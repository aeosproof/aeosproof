// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title AEOSUnifiedSovereignAnchor
 * @author Emil Jansson / AEOS Fiduciary Systems & Economic Oversight
 * @notice Förenad institutionell notarieförankring och Groth16 BN254 parningsverifierare (111 586 034 verifikat).
 * @dev Integrerar E01 Merkle CAS och EIP-197 on-chain pairing precompiles (0x06, 0x07, 0x08) i ett enda gasoptimerat kontrakt.
 */
contract AEOSUnifiedSovereignAnchor {
    string public constant INSTITUTION = "AEOS Fiduciary Systems & Economic Oversight";
    string public constant FOUNDER = "Emil Jansson";
    string public constant VERIFICATION_STANDARD = "E01 Merkle CAS / SP1 zkVM / Groth16 BN254";

    uint256 internal constant R_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant P_MOD = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    bytes32 public constant CANONICAL_MERKLE_ROOT = 0x6a40bf77c2ba34e9000d50d82241fc4526b0c11ceb2382131ba653fd88834c4e;
    uint64 public constant CANONICAL_POPULATION = 111_586_034;
    uint256 public constant CANONICAL_VOLUME_ORE = 83366155606397; // 833 661 556 063,97 SEK
    uint256 public constant CANONICAL_ANOMALIES_ORE = 2523841970164; // 25 238 419 701,64 SEK
    uint16 public constant CANONICAL_AUTHORITIES = 193;

    address public immutable NOTARIZER;
    uint256 public immutable ANCHOR_TIMESTAMP;
    bytes32 public immutable ZKVM_PROGRAM_VKEY;

    // G1/G2 Verifieringsnyckelpunkter genererade från gnark BN254 export
    uint256 internal constant ALFA_X = 0x2411e74b97d2e4dd60523db48cae5549887b404d0929bf4ee1e550c6bf5e5eb5;
    uint256 internal constant ALFA_Y = 0x22896d91bb3a9d53c799a7708fa8fa7d6f03d5cfbe474b7e4162799c8bf2d708;

    uint256 internal constant BETA_X1 = 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 internal constant BETA_X2 = 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 internal constant BETA_Y1 = 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;
    uint256 internal constant BETA_Y2 = 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;

    uint256 internal constant GAMMA_X1 = 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
    uint256 internal constant GAMMA_X2 = 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
    uint256 internal constant GAMMA_Y1 = 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;
    uint256 internal constant GAMMA_Y2 = 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;

    uint256 internal constant DELTA_X1 = 0x2a9cdbe7e0e7a6faea01e5da2d8a4e1d5e3f42ec7d6a45e4e7e6005d5ea66f44;
    uint256 internal constant DELTA_X2 = 0x14041d5b3d68615b130cf6ae196f7e8a933fffe8b5606d2745e1eb2a1d2834b6;
    uint256 internal constant DELTA_Y1 = 0x07f4650630b42c8d23460678685c2c7700e5720d20d45648834f826012a64797;
    uint256 internal constant DELTA_Y2 = 0x17c91a0c4f82c2b3e8e7c27d49e6f3aa56fb8868f0f08144b200b217a6a72e81;

    // IC (Input Commitments) baspunkter i G1 för 4 publika signaler
    uint256 internal constant IC0_X = 0x067e7c8441eb5db0d66c1f1ec71752bd5ff0d1a4993d3957242d5916053303a9;
    uint256 internal constant IC0_Y = 0x1cb61d81242fb59b12d548f0811e5f5f4b437c35f7ba1207e32408bcfb400787;
    uint256 internal constant IC1_X = 0x1d3bc28ea2ca1d2d385f9bc68cdcb1a213fa66db10a9557a15a81a28892f396a;
    uint256 internal constant IC1_Y = 0x2424eb0e945c7eb1665a9533f82cb5069b1ad899ef87b075fd250278788414bf;
    uint256 internal constant IC2_X = 0x087d32c5896a29772ae8d4ecaa2666a3d9061df400032906d289063bc430e38a;
    uint256 internal constant IC2_Y = 0x13824f46ff3611ccfeeb9c9b5f928e4e7e8b693240fb2fd44e234850fa986a42;
    uint256 internal constant IC3_X = 0x2984534a2e2d09eb0927df4d6be2069cbcd1eb31a293673c98aaae2525492d24;
    uint256 internal constant IC3_Y = 0x05f8846c2d1b7a2bb3c80f6e1f0e42777ae3ae245dfba4220b3cb1c9b2e88a0e;
    uint256 internal constant IC4_X = 0x2f974cb185c7bb7eef9f270a2569527ec318d1844bda247f0e3039d675e01c18;
    uint256 internal constant IC4_Y = 0x117498c39e0839f268f70044cf4d216d2db969a531eec46ef17b43a9ad09559c;

    bytes32 public activeNationalRoot;
    uint256 public totalSealedAnomaliesOre;
    bool public isNationalProofSealed;

    event DossierAnchored(
        bytes32 indexed merkleRoot,
        uint64 recordCount,
        uint256 volumeOre,
        address indexed notarizer,
        uint256 timestamp
    );

    event NationalAuditSealed(
        uint256 indexed timestamp,
        uint64 indexed totalVouchers,
        uint256 totalVolumeOre,
        uint256 identifiedAnomaliesOre,
        bytes32 merkleRoot,
        bytes32 proofHash
    );

    event MunicipalInclusionVerified(
        uint16 indexed municipalityCode,
        string municipalityName,
        uint256 municipalAnomalyOre,
        bytes32 indexed nationalMerkleRoot,
        bool verified
    );

    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct NationalSignals {
        uint64 totalVouchers;
        uint256 totalVolumeOre;
        uint256 identifiedAnomaliesOre;
        bytes32 merkleRoot;
    }

    constructor(bytes32 _zkvmVkey) {
        NOTARIZER = msg.sender;
        ANCHOR_TIMESTAMP = block.timestamp;
        ZKVM_PROGRAM_VKEY = _zkvmVkey;
        activeNationalRoot = CANONICAL_MERKLE_ROOT;

        emit DossierAnchored(
            CANONICAL_MERKLE_ROOT,
            CANONICAL_POPULATION,
            CANONICAL_VOLUME_ORE,
            msg.sender,
            block.timestamp
        );
    }

    /// @notice Bakåtkompatibilitet med AEOSFiduciaryAnchor: verifiera om en rot matchar det förseglade ankaret
    function verifyDigest(bytes32 digest) external view returns (bool) {
        return digest == CANONICAL_MERKLE_ROOT;
    }

    function sealNationalLedgerProof(
        Proof calldata proof,
        NationalSignals calldata signals
    ) external returns (bool) {
        require(!isNationalProofSealed, "PROOF_ALREADY_SEALED");
        require(signals.totalVouchers == CANONICAL_POPULATION, "INVALID_POPULATION_COUNT");
        require(signals.totalVolumeOre == CANONICAL_VOLUME_ORE, "INVALID_GROSS_VOLUME");
        require(signals.merkleRoot == CANONICAL_MERKLE_ROOT, "INVALID_MERKLE_ROOT");

        uint256[4] memory input;
        input[0] = signals.totalVouchers;
        input[1] = signals.totalVolumeOre;
        input[2] = signals.identifiedAnomaliesOre;
        input[3] = uint256(signals.merkleRoot);

        for (uint256 i = 0; i < 4; i++) {
            require(input[i] < R_MOD, "SIGNAL_EXCEEDS_FIELD_MODULUS");
        }

        require(verifyGroth16(proof, input), "GROTH16_PAIRING_FAILED");

        totalSealedAnomaliesOre = signals.identifiedAnomaliesOre;
        isNationalProofSealed = true;

        bytes32 proofHash = keccak256(abi.encode(proof.a, proof.b, proof.c));

        emit NationalAuditSealed(
            block.timestamp,
            signals.totalVouchers,
            signals.totalVolumeOre,
            signals.identifiedAnomaliesOre,
            signals.merkleRoot,
            proofHash
        );

        return true;
    }

    function verifyMunicipalSelectiveDisclosure(
        uint16 municipalityCode,
        string calldata municipalityName,
        uint256 municipalAnomalyOre,
        bytes32[] calldata merkleBranch
    ) external returns (bool) {
        bytes32 computedRoot = keccak256(abi.encodePacked(municipalityCode, municipalAnomalyOre));
        for (uint256 i = 0; i < merkleBranch.length; i++) {
            bytes32 proofElement = merkleBranch[i];
            if (computedRoot <= proofElement) {
                computedRoot = keccak256(abi.encodePacked(computedRoot, proofElement));
            } else {
                computedRoot = keccak256(abi.encodePacked(proofElement, computedRoot));
            }
        }

        require(computedRoot == CANONICAL_MERKLE_ROOT, "INCLUSION_PROOF_MISMATCH");

        emit MunicipalInclusionVerified(
            municipalityCode,
            municipalityName,
            municipalAnomalyOre,
            CANONICAL_MERKLE_ROOT,
            true
        );

        return true;
    }

    function verifyGroth16(Proof calldata proof, uint256[4] memory input) internal view returns (bool) {
        uint256[2] memory vk_x = [IC0_X, IC0_Y];
        uint256[2][4] memory ic = [[IC1_X, IC1_Y], [IC2_X, IC2_Y], [IC3_X, IC3_Y], [IC4_X, IC4_Y]];

        for (uint256 i = 0; i < 4; i++) {
            uint256[2] memory term = ecMul(ic[i][0], ic[i][1], input[i]);
            vk_x = ecAdd(vk_x[0], vk_x[1], term[0], term[1]);
        }

        uint256 negA_Y = P_MOD - (proof.a[1] % P_MOD);

        uint256[24] memory pairInput;
        pairInput[0]  = proof.a[0];
        pairInput[1]  = negA_Y;
        pairInput[2]  = proof.b[0][1];
        pairInput[3]  = proof.b[0][0];
        pairInput[4]  = proof.b[1][1];
        pairInput[5]  = proof.b[1][0];

        pairInput[6]  = ALFA_X;
        pairInput[7]  = ALFA_Y;
        pairInput[8]  = BETA_X1;
        pairInput[9]  = BETA_X2;
        pairInput[10] = BETA_Y1;
        pairInput[11] = BETA_Y2;

        pairInput[12] = vk_x[0];
        pairInput[13] = vk_x[1];
        pairInput[14] = GAMMA_X1;
        pairInput[15] = GAMMA_X2;
        pairInput[16] = GAMMA_Y1;
        pairInput[17] = GAMMA_Y2;

        pairInput[18] = proof.c[0];
        pairInput[19] = proof.c[1];
        pairInput[20] = DELTA_X1;
        pairInput[21] = DELTA_X2;
        pairInput[22] = DELTA_Y1;
        pairInput[23] = DELTA_Y2;

        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 0x08, pairInput, 0x300, out, 0x20)
        }
        return success && out[0] == 1;
    }

    function ecAdd(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal view returns (uint256[2] memory r) {
        uint256[4] memory input = [x1, y1, x2, y2];
        assembly {
            if iszero(staticcall(not(0), 0x06, input, 0x80, r, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMul(uint256 x, uint256 y, uint256 s) internal view returns (uint256[2] memory r) {
        uint256[3] memory input = [x, y, s];
        assembly {
            if iszero(staticcall(not(0), 0x07, input, 0x60, r, 0x40)) {
                revert(0, 0)
            }
        }
    }
}
