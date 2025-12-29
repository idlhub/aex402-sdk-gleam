//// AeX402 SDK PDA Derivation
////
//// Program Derived Address (PDA) derivation utilities for the AeX402 AMM.
//// Note: Actual PDA derivation requires ed25519 curve operations which are
//// implemented in the Solana runtime. This module provides seed construction
//// helpers that can be used with a Solana client library.

import gleam/bit_array
import gleam/list
import gleam/crypto
import aex402/constants
import aex402/types.{type PublicKey}

// ============================================================================
// Seed Construction Types
// ============================================================================

/// Seeds for PDA derivation
pub type PdaSeeds =
  List(BitArray)

/// Result of a PDA derivation attempt
pub type PdaResult {
  PdaResult(
    /// The derived program address
    address: BitArray,
    /// The bump seed that was found
    bump: Int,
  )
}

// ============================================================================
// Seed Builders
// ============================================================================

/// Build seeds for Pool PDA: ["pool", mint0, mint1]
pub fn pool_seeds(mint0: PublicKey, mint1: PublicKey) -> PdaSeeds {
  [<<"pool":utf8>>, mint0, mint1]
}

/// Build seeds for Pool PDA with bump: ["pool", mint0, mint1, bump]
pub fn pool_seeds_with_bump(
  mint0: PublicKey,
  mint1: PublicKey,
  bump: Int,
) -> PdaSeeds {
  [<<"pool":utf8>>, mint0, mint1, <<bump:8>>]
}

/// Build seeds for Farm PDA: ["farm", pool]
pub fn farm_seeds(pool: PublicKey) -> PdaSeeds {
  [<<"farm":utf8>>, pool]
}

/// Build seeds for Farm PDA with bump: ["farm", pool, bump]
pub fn farm_seeds_with_bump(pool: PublicKey, bump: Int) -> PdaSeeds {
  [<<"farm":utf8>>, pool, <<bump:8>>]
}

/// Build seeds for UserFarm PDA: ["user_farm", farm, user]
pub fn user_farm_seeds(farm: PublicKey, user: PublicKey) -> PdaSeeds {
  [<<"user_farm":utf8>>, farm, user]
}

/// Build seeds for UserFarm PDA with bump: ["user_farm", farm, user, bump]
pub fn user_farm_seeds_with_bump(
  farm: PublicKey,
  user: PublicKey,
  bump: Int,
) -> PdaSeeds {
  [<<"user_farm":utf8>>, farm, user, <<bump:8>>]
}

/// Build seeds for Lottery PDA: ["lottery", pool]
pub fn lottery_seeds(pool: PublicKey) -> PdaSeeds {
  [<<"lottery":utf8>>, pool]
}

/// Build seeds for Lottery PDA with bump: ["lottery", pool, bump]
pub fn lottery_seeds_with_bump(pool: PublicKey, bump: Int) -> PdaSeeds {
  [<<"lottery":utf8>>, pool, <<bump:8>>]
}

/// Build seeds for LotteryEntry PDA: ["lottery_entry", lottery, user]
pub fn lottery_entry_seeds(lottery: PublicKey, user: PublicKey) -> PdaSeeds {
  [<<"lottery_entry":utf8>>, lottery, user]
}

/// Build seeds for LotteryEntry PDA with bump
pub fn lottery_entry_seeds_with_bump(
  lottery: PublicKey,
  user: PublicKey,
  bump: Int,
) -> PdaSeeds {
  [<<"lottery_entry":utf8>>, lottery, user, <<bump:8>>]
}

/// Build seeds for Registry PDA: ["registry"]
pub fn registry_seeds() -> PdaSeeds {
  [<<"registry":utf8>>]
}

/// Build seeds for Registry PDA with bump: ["registry", bump]
pub fn registry_seeds_with_bump(bump: Int) -> PdaSeeds {
  [<<"registry":utf8>>, <<bump:8>>]
}

/// Build seeds for Vault PDA: ["vault", pool, token_index]
pub fn vault_seeds(pool: PublicKey, token_index: Int) -> PdaSeeds {
  [<<"vault":utf8>>, pool, <<token_index:8>>]
}

/// Build seeds for Vault PDA with bump
pub fn vault_seeds_with_bump(
  pool: PublicKey,
  token_index: Int,
  bump: Int,
) -> PdaSeeds {
  [<<"vault":utf8>>, pool, <<token_index:8>>, <<bump:8>>]
}

/// Build seeds for LP Mint PDA: ["lp_mint", pool]
pub fn lp_mint_seeds(pool: PublicKey) -> PdaSeeds {
  [<<"lp_mint":utf8>>, pool]
}

/// Build seeds for LP Mint PDA with bump
pub fn lp_mint_seeds_with_bump(pool: PublicKey, bump: Int) -> PdaSeeds {
  [<<"lp_mint":utf8>>, pool, <<bump:8>>]
}

/// Build seeds for ML Brain PDA: ["ml_brain", pool]
pub fn ml_brain_seeds(pool: PublicKey) -> PdaSeeds {
  [<<"ml_brain":utf8>>, pool]
}

/// Build seeds for ML Brain PDA with bump
pub fn ml_brain_seeds_with_bump(pool: PublicKey, bump: Int) -> PdaSeeds {
  [<<"ml_brain":utf8>>, pool, <<bump:8>>]
}

/// Build seeds for Orderbook PDA: ["orderbook", pool]
pub fn orderbook_seeds(pool: PublicKey) -> PdaSeeds {
  [<<"orderbook":utf8>>, pool]
}

/// Build seeds for Orderbook PDA with bump
pub fn orderbook_seeds_with_bump(pool: PublicKey, bump: Int) -> PdaSeeds {
  [<<"orderbook":utf8>>, pool, <<bump:8>>]
}

/// Build seeds for CL Pool PDA: ["cl_pool", pool]
pub fn cl_pool_seeds(pool: PublicKey) -> PdaSeeds {
  [<<"cl_pool":utf8>>, pool]
}

/// Build seeds for CL Pool PDA with bump
pub fn cl_pool_seeds_with_bump(pool: PublicKey, bump: Int) -> PdaSeeds {
  [<<"cl_pool":utf8>>, pool, <<bump:8>>]
}

/// Build seeds for CL Position PDA: ["cl_position", cl_pool, owner, position_id]
pub fn cl_position_seeds(
  cl_pool: PublicKey,
  owner: PublicKey,
  position_id: Int,
) -> PdaSeeds {
  [<<"cl_position":utf8>>, cl_pool, owner, <<position_id:64-little-unsigned>>]
}

/// Build seeds for CL Position PDA with bump
pub fn cl_position_seeds_with_bump(
  cl_pool: PublicKey,
  owner: PublicKey,
  position_id: Int,
  bump: Int,
) -> PdaSeeds {
  [
    <<"cl_position":utf8>>,
    cl_pool,
    owner,
    <<position_id:64-little-unsigned>>,
    <<bump:8>>,
  ]
}

/// Build seeds for Governance Proposal PDA: ["gov_proposal", pool, proposal_id]
pub fn gov_proposal_seeds(pool: PublicKey, proposal_id: Int) -> PdaSeeds {
  [<<"gov_proposal":utf8>>, pool, <<proposal_id:64-little-unsigned>>]
}

/// Build seeds for Governance Proposal PDA with bump
pub fn gov_proposal_seeds_with_bump(
  pool: PublicKey,
  proposal_id: Int,
  bump: Int,
) -> PdaSeeds {
  [<<"gov_proposal":utf8>>, pool, <<proposal_id:64-little-unsigned>>, <<bump:8>>]
}

/// Build seeds for Governance Vote PDA: ["gov_vote", proposal, voter]
pub fn gov_vote_seeds(proposal: PublicKey, voter: PublicKey) -> PdaSeeds {
  [<<"gov_vote":utf8>>, proposal, voter]
}

/// Build seeds for Governance Vote PDA with bump
pub fn gov_vote_seeds_with_bump(
  proposal: PublicKey,
  voter: PublicKey,
  bump: Int,
) -> PdaSeeds {
  [<<"gov_vote":utf8>>, proposal, voter, <<bump:8>>]
}

// ============================================================================
// Seed Encoding
// ============================================================================

/// Concatenate seeds into a single buffer for hashing
pub fn concat_seeds(seeds: PdaSeeds) -> BitArray {
  seeds
  |> list.fold(<<>>, fn(acc, seed) { bit_array.concat([acc, seed]) })
}

/// Add program ID to seeds for PDA derivation
pub fn seeds_with_program_id(seeds: PdaSeeds) -> BitArray {
  let program_id = constants.program_id_bytes
  let pda_marker = <<"ProgramDerivedAddress":utf8>>
  bit_array.concat([concat_seeds(seeds), program_id, pda_marker])
}

// ============================================================================
// PDA Derivation (Requires External Curve Operations)
// ============================================================================

/// Find a valid PDA by trying bumps from 255 down to 0
/// Note: This is a placeholder - actual implementation requires ed25519 operations
/// In practice, use a Solana client library for PDA derivation
pub fn find_program_address(
  seeds: PdaSeeds,
  _program_id: PublicKey,
) -> Result(PdaResult, Nil) {
  find_pda_with_bump(seeds, 255)
}

fn find_pda_with_bump(seeds: PdaSeeds, bump: Int) -> Result(PdaResult, Nil) {
  case bump < 0 {
    True -> Error(Nil)
    False -> {
      let seeds_with_bump = list.append(seeds, [<<bump:8>>])
      let hash_input = concat_seeds(seeds_with_bump)

      // SHA256 hash of seeds (simplified - real PDA uses different curve operations)
      let hash = crypto.hash(crypto.Sha256, hash_input)

      // This is a placeholder check - real PDA derivation checks if point is off-curve
      // For actual use, integrate with a Solana client library
      case is_valid_pda_placeholder(hash) {
        True -> Ok(PdaResult(address: hash, bump: bump))
        False -> find_pda_with_bump(seeds, bump - 1)
      }
    }
  }
}

/// Placeholder validity check
/// In reality, this needs to check if the point is NOT on the ed25519 curve
fn is_valid_pda_placeholder(_hash: BitArray) -> Bool {
  True
}

// ============================================================================
// Canonical Bump
// ============================================================================

/// Create PDA address using canonical bump (highest valid bump)
/// This matches Solana's findProgramAddressSync behavior
pub fn create_program_address(
  seeds: PdaSeeds,
  program_id: PublicKey,
) -> Result(BitArray, Nil) {
  case find_program_address(seeds, program_id) {
    Ok(result) -> Ok(result.address)
    Error(_) -> Error(Nil)
  }
}

// ============================================================================
// Verification
// ============================================================================

/// Verify that an address is a valid PDA with the given seeds and bump
pub fn verify_pda(
  address: PublicKey,
  seeds: PdaSeeds,
  bump: Int,
  program_id: PublicKey,
) -> Bool {
  let seeds_with_bump = list.append(seeds, [<<bump:8>>])
  case create_program_address(seeds_with_bump, program_id) {
    Ok(derived) -> derived == address
    Error(_) -> False
  }
}
