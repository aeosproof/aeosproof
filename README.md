# Building systems that can show their work.

Software developer working at the intersection of smart contracts, cryptographic provenance, distributed systems, and legal/financial data infrastructure.

I like difficult problems, reproducible results, and systems that can explain *why* they believe something — not just confidently return `true`.

### Currently working on

- **[ENS smart-wallet compatibility](https://github.com/ensdomains/ens-contracts/pull/577)** — contributing a fix for refund paths that can fail under Solidity's 2,300-gas `transfer()` stipend.
- **[AEOS / Boreal Proof](https://aeosinstitutet.se/)** — evidence-centric infrastructure for data provenance, deterministic reconciliation, and verifiable claims.
- **Adversarial testing** — fuzzing, regression suites, invariant analysis, and trying to prove my own assumptions wrong before someone else does.

### Engineering philosophy

- Reproducibility over rhetoric.
- Evidence over confidence.
- Fail closed. Verify independently.
- If a result cannot be reproduced, it is a hypothesis wearing a nice suit.

I tend to build the verification tooling, run the edge cases, inspect the artifacts, and then run everything again because the first result looked suspiciously convenient.

**Currently:** Making systems more trustworthy, one inconvenient edge case at a time.

*Occasionally, the edge case is the entire project.*

---

## 🏛️ Sovereign EVM & Cryptographic Notarization Infrastructure

Repository housing the immutable EVM contracts, verification precompiles, and ABI specifications anchoring **Sweden's National Municipal & Regional Supplier Ledgers (111,586,034 vouchers / 833.66B SEK)** onto Ethereum Mainnet.

### ⛓️ Deployed Mainnet Contracts

| Contract | Network | Address | Verification Status | Block |
|:---|:---|:---|:---:|:---:|
| **AEOSFiduciaryAnchor** | Ethereum Mainnet | [`0x5Bd889Fb8fa5D17a7517cB46B3d71f5e12B32DE9`](https://etherscan.io/address/0x5Bd889Fb8fa5D17a7517cB46B3d71f5e12B32DE9) | **Verified (Pass)** | `26306885` |
| **SwedenNationalVerifier** | Ethereum Mainnet | [`0x08DbE511b52bB5fF9044709eC11404C18578d3f5`](https://etherscan.io/address/0x08DbE511b52bB5fF9044709eC11404C18578d3f5) | **Verified (Pass)** | `26306885` |
| **Historical Anchor (71M)** | Ethereum Mainnet | [`0x6FaeDC7Dfe683bD60BD87f51B3bDFcdcA328fe94`](https://etherscan.io/address/0x6FaeDC7Dfe683bD60BD87f51B3bDFcdcA328fe94) | **Verified (Pass)** | `26189912` |

### 🔒 Cryptographic Invariants & Merkle CAS

- **Canonical Merkle Root ($C_{\text{ROOT}}$):**  
  `0x6a40bf77c2ba34e9000d50d82241fc4526b0c11ceb2382131ba653fd88834c4e`
- **Total Ingested Population:**  
  `111,586,034` transactions across 290 municipalities and 21 regions.
- **Gross Reconciled Volume:**  
  `833,661,556,063.97` SEK (`83366155606397` öre).
- **Proving Standard:**  
  SP1 RISC-V zkVM (`reskontra-guest`) with Groth16 BN254 SNARK wrapping evaluated against EVM precompile `0x08` (EIP-197).

### 🔍 Independent On-Chain Verification

Verify the immutable notarization directly from any terminal using `cast`:

```bash
# Verify the digest against the canonical fiduciary anchor (returns true)
cast call 0x5Bd889Fb8fa5D17a7517cB46B3d71f5e12B32DE9 \
  "verifyDigest(bytes32)(bool)" \
  0x6a40bf77c2ba34e9000d50d82241fc4526b0c11ceb2382131ba653fd88834c4e \
  --rpc-url https://eth.llamarpc.com
```

### 📦 Developer Tools & Dashboard

- **GitMyABI Dashboard:** [gitmyabi.com/dashboard/aeosproofs-team-743a4a67](https://gitmyabi.com/dashboard/aeosproofs-team-743a4a67)
- **Live In-Browser Verifier:** [aeosinstitutet.se/verifiera](https://aeosinstitutet.se/verifiera)
- **3D Interactive Proof Radar:** [aeosinstitutet.se/radar](https://aeosinstitutet.se/radar)
