//// AeX402 SDK Instruction Building
////
//// Functions for building instruction data as BitArrays.
//// The instruction format is: 8-byte discriminator + serialized arguments.

import gleam/bit_array
import gleam/int
import gleam/list
import aex402/constants
import aex402/types.{
  type AddLiq1Args, type AddLiqArgs, type CommitAmpArgs, type CreateFarmArgs,
  type CreateLotteryArgs, type CreateNPoolArgs, type CreatePoolArgs,
  type DrawLotteryArgs, type EnterLotteryArgs, type LockLpArgs,
  type PublicKey, type RampAmpArgs, type RemLiqArgs, type StakeArgs,
  type SwapArgs, type SwapNArgs, type SwapSimpleArgs, type TwapWindow,
  type UpdateFeeArgs,
}

// ============================================================================
// Helper Functions for Writing Binary Data (Little-Endian)
// ============================================================================

/// Write unsigned 8-bit integer to BitArray
fn write_u8(value: Int) -> BitArray {
  <<value:8>>
}

/// Write unsigned 64-bit integer (little-endian)
fn write_u64_le(value: Int) -> BitArray {
  <<value:64-little-unsigned>>
}

/// Write signed 64-bit integer (little-endian)
fn write_i64_le(value: Int) -> BitArray {
  <<value:64-little-signed>>
}

/// Write bool as u8
fn write_bool(value: Bool) -> BitArray {
  case value {
    True -> <<1:8>>
    False -> <<0:8>>
  }
}

// ============================================================================
// Pool Creation Instructions
// ============================================================================

/// Build instruction data for createpool
pub fn build_create_pool(args: CreatePoolArgs) -> BitArray {
  bit_array.concat([
    constants.disc_createpool,
    write_u64_le(args.amp),
    write_u8(args.bump),
  ])
}

/// Build instruction data for createpn (N-token pool)
pub fn build_create_npool(args: CreateNPoolArgs) -> BitArray {
  bit_array.concat([
    constants.disc_createpn,
    write_u64_le(args.amp),
    write_u8(args.n_tokens),
    write_u8(args.bump),
  ])
}

/// Build instruction data for initt0v (initialize token 0 vault)
pub fn build_init_t0_vault() -> BitArray {
  constants.disc_initt0v
}

/// Build instruction data for initt1v (initialize token 1 vault)
pub fn build_init_t1_vault() -> BitArray {
  constants.disc_initt1v
}

/// Build instruction data for initlpm (initialize LP mint)
pub fn build_init_lp_mint() -> BitArray {
  constants.disc_initlpm
}

// ============================================================================
// Swap Instructions
// ============================================================================

/// Build instruction data for generic swap
pub fn build_swap(args: SwapArgs) -> BitArray {
  bit_array.concat([
    constants.disc_swap,
    write_u8(args.from),
    write_u8(args.to),
    write_u64_le(args.amount_in),
    write_u64_le(args.min_out),
    write_i64_le(args.deadline),
  ])
}

/// Build instruction data for swap t0 to t1
pub fn build_swap_t0_t1(args: SwapSimpleArgs) -> BitArray {
  bit_array.concat([
    constants.disc_swapt0t1,
    write_u64_le(args.amount_in),
    write_u64_le(args.min_out),
  ])
}

/// Build instruction data for swap t1 to t0
pub fn build_swap_t1_t0(args: SwapSimpleArgs) -> BitArray {
  bit_array.concat([
    constants.disc_swapt1t0,
    write_u64_le(args.amount_in),
    write_u64_le(args.min_out),
  ])
}

/// Build instruction data for N-token swap
pub fn build_swap_n(args: SwapNArgs) -> BitArray {
  bit_array.concat([
    constants.disc_swapn,
    write_u8(args.from_idx),
    write_u8(args.to_idx),
    write_u64_le(args.amount_in),
    write_u64_le(args.min_out),
  ])
}

/// Build instruction data for migration swap t0 to t1
pub fn build_migrate_t0_t1(amount_in: Int, min_out: Int) -> BitArray {
  bit_array.concat([
    constants.disc_migt0t1,
    write_u64_le(amount_in),
    write_u64_le(min_out),
  ])
}

/// Build instruction data for migration swap t1 to t0
pub fn build_migrate_t1_t0(amount_in: Int, min_out: Int) -> BitArray {
  bit_array.concat([
    constants.disc_migt1t0,
    write_u64_le(amount_in),
    write_u64_le(min_out),
  ])
}

// ============================================================================
// Liquidity Instructions
// ============================================================================

/// Build instruction data for adding liquidity (2-token)
pub fn build_add_liquidity(args: AddLiqArgs) -> BitArray {
  bit_array.concat([
    constants.disc_addliq,
    write_u64_le(args.amount0),
    write_u64_le(args.amount1),
    write_u64_le(args.min_lp),
  ])
}

/// Build instruction data for single-sided add liquidity
pub fn build_add_liquidity_1(args: AddLiq1Args) -> BitArray {
  bit_array.concat([
    constants.disc_addliq1,
    write_u64_le(args.amount_in),
    write_u64_le(args.min_lp),
  ])
}

/// Build instruction data for N-token add liquidity
pub fn build_add_liquidity_n(amounts: List(Int), min_lp: Int) -> BitArray {
  let amount_bytes = list.map(amounts, write_u64_le)
  bit_array.concat([
    constants.disc_addliqn,
    ..list.append(amount_bytes, [write_u64_le(min_lp)])
  ])
}

/// Build instruction data for removing liquidity (2-token)
pub fn build_remove_liquidity(args: RemLiqArgs) -> BitArray {
  bit_array.concat([
    constants.disc_remliq,
    write_u64_le(args.lp_amount),
    write_u64_le(args.min0),
    write_u64_le(args.min1),
  ])
}

/// Build instruction data for N-token remove liquidity
pub fn build_remove_liquidity_n(lp_amount: Int, min_amounts: List(Int)) -> BitArray {
  let min_bytes = list.map(min_amounts, write_u64_le)
  bit_array.concat([constants.disc_remliqn, write_u64_le(lp_amount), ..min_bytes])
}

// ============================================================================
// Admin Instructions
// ============================================================================

/// Build instruction data for set pause
pub fn build_set_pause(paused: Bool) -> BitArray {
  bit_array.concat([constants.disc_setpause, write_bool(paused)])
}

/// Build instruction data for update fee
pub fn build_update_fee(args: UpdateFeeArgs) -> BitArray {
  bit_array.concat([constants.disc_updfee, write_u64_le(args.fee_bps)])
}

/// Build instruction data for withdraw admin fees
pub fn build_withdraw_fee() -> BitArray {
  constants.disc_wdrawfee
}

/// Build instruction data for commit amp change
pub fn build_commit_amp(args: CommitAmpArgs) -> BitArray {
  bit_array.concat([constants.disc_commitamp, write_u64_le(args.target_amp)])
}

/// Build instruction data for ramp amp
pub fn build_ramp_amp(args: RampAmpArgs) -> BitArray {
  bit_array.concat([
    constants.disc_rampamp,
    write_u64_le(args.target_amp),
    write_i64_le(args.duration),
  ])
}

/// Build instruction data for stop ramp
pub fn build_stop_ramp() -> BitArray {
  constants.disc_stopramp
}

/// Build instruction data for initiate authority transfer
pub fn build_init_auth_transfer() -> BitArray {
  constants.disc_initauth
}

/// Build instruction data for complete authority transfer
pub fn build_complete_auth_transfer() -> BitArray {
  constants.disc_complauth
}

/// Build instruction data for cancel authority transfer
pub fn build_cancel_auth_transfer() -> BitArray {
  constants.disc_cancelauth
}

// ============================================================================
// Farming Instructions
// ============================================================================

/// Build instruction data for create farm
pub fn build_create_farm(args: CreateFarmArgs) -> BitArray {
  bit_array.concat([
    constants.disc_createfarm,
    write_u64_le(args.reward_rate),
    write_i64_le(args.start_time),
    write_i64_le(args.end_time),
  ])
}

/// Build instruction data for stake LP
pub fn build_stake_lp(args: StakeArgs) -> BitArray {
  bit_array.concat([constants.disc_stakelp, write_u64_le(args.amount)])
}

/// Build instruction data for unstake LP
pub fn build_unstake_lp(args: StakeArgs) -> BitArray {
  bit_array.concat([constants.disc_unstakelp, write_u64_le(args.amount)])
}

/// Build instruction data for claim farm rewards
pub fn build_claim_farm() -> BitArray {
  constants.disc_claimfarm
}

/// Build instruction data for lock LP tokens
pub fn build_lock_lp(args: LockLpArgs) -> BitArray {
  bit_array.concat([
    constants.disc_locklp,
    write_u64_le(args.amount),
    write_i64_le(args.duration),
  ])
}

/// Build instruction data for claim unlocked LP
pub fn build_claim_unlocked_lp() -> BitArray {
  constants.disc_claimulp
}

// ============================================================================
// Lottery Instructions
// ============================================================================

/// Build instruction data for create lottery
pub fn build_create_lottery(args: CreateLotteryArgs) -> BitArray {
  bit_array.concat([
    constants.disc_createlot,
    write_u64_le(args.ticket_price),
    write_i64_le(args.end_time),
  ])
}

/// Build instruction data for enter lottery
pub fn build_enter_lottery(args: EnterLotteryArgs) -> BitArray {
  bit_array.concat([constants.disc_enterlot, write_u64_le(args.ticket_count)])
}

/// Build instruction data for draw lottery
pub fn build_draw_lottery(args: DrawLotteryArgs) -> BitArray {
  bit_array.concat([constants.disc_drawlot, write_u64_le(args.random_seed)])
}

/// Build instruction data for claim lottery prize
pub fn build_claim_lottery() -> BitArray {
  constants.disc_claimlot
}

// ============================================================================
// Registry Instructions
// ============================================================================

/// Build instruction data for initialize registry
pub fn build_init_registry() -> BitArray {
  constants.disc_initreg
}

/// Build instruction data for register pool
pub fn build_register_pool() -> BitArray {
  constants.disc_regpool
}

/// Build instruction data for unregister pool
pub fn build_unregister_pool() -> BitArray {
  constants.disc_unregpool
}

// ============================================================================
// TWAP Oracle Instruction
// ============================================================================

/// Build instruction data for get TWAP
pub fn build_get_twap(window: TwapWindow) -> BitArray {
  bit_array.concat([
    constants.disc_gettwap,
    write_u8(constants.twap_window_to_byte(window)),
  ])
}

// ============================================================================
// Circuit Breaker Instructions
// ============================================================================

/// Build instruction data for set circuit breaker
pub fn build_set_circuit_breaker(
  price_dev_bps: Int,
  volume_mult: Int,
  cooldown_slots: Int,
  auto_resume_slots: Int,
) -> BitArray {
  bit_array.concat([
    constants.disc_setcb,
    write_u64_le(price_dev_bps),
    write_u64_le(volume_mult),
    write_u64_le(cooldown_slots),
    write_u64_le(auto_resume_slots),
  ])
}

/// Build instruction data for reset circuit breaker
pub fn build_reset_circuit_breaker() -> BitArray {
  constants.disc_resetcb
}

// ============================================================================
// Rate Limiting Instructions
// ============================================================================

/// Build instruction data for set rate limit
pub fn build_set_rate_limit(max_volume: Int, max_swaps: Int) -> BitArray {
  bit_array.concat([
    constants.disc_setrl,
    write_u64_le(max_volume),
    write_u64_le(max_swaps),
  ])
}

// ============================================================================
// Oracle Instructions
// ============================================================================

/// Build instruction data for set oracle
pub fn build_set_oracle(
  max_staleness: Int,
  max_deviation_bps: Int,
) -> BitArray {
  bit_array.concat([
    constants.disc_setoracle,
    write_u64_le(max_staleness),
    write_u64_le(max_deviation_bps),
  ])
}

// ============================================================================
// Governance Instructions
// ============================================================================

/// Governance proposal types
pub type ProposalType {
  ProposalFeeChange
  ProposalAmpChange
  ProposalAdminFee
  ProposalPause
  ProposalAuthority
}

/// Convert proposal type to byte value
pub fn proposal_type_to_byte(ptype: ProposalType) -> Int {
  case ptype {
    ProposalFeeChange -> 1
    ProposalAmpChange -> 2
    ProposalAdminFee -> 3
    ProposalPause -> 4
    ProposalAuthority -> 5
  }
}

/// Build instruction data for governance proposal
pub fn build_gov_proposal(
  proposal_type: ProposalType,
  value: Int,
) -> BitArray {
  bit_array.concat([
    constants.disc_govprop,
    write_u8(proposal_type_to_byte(proposal_type)),
    write_u64_le(value),
  ])
}

/// Build instruction data for governance vote
pub fn build_gov_vote(vote_for: Bool) -> BitArray {
  bit_array.concat([constants.disc_govvote, write_bool(vote_for)])
}

/// Build instruction data for governance execute
pub fn build_gov_execute() -> BitArray {
  constants.disc_govexec
}

/// Build instruction data for governance cancel
pub fn build_gov_cancel() -> BitArray {
  constants.disc_govcncl
}

// ============================================================================
// Orderbook Instructions
// ============================================================================

/// Build instruction data for initialize orderbook
pub fn build_init_orderbook() -> BitArray {
  constants.disc_initbook
}

/// Order type
pub type OrderType {
  OrderBuy
  OrderSell
}

/// Build instruction data for place order
pub fn build_place_order(
  order_type: OrderType,
  price: Int,
  amount: Int,
  expiry: Int,
) -> BitArray {
  let order_byte = case order_type {
    OrderBuy -> 0
    OrderSell -> 1
  }
  bit_array.concat([
    constants.disc_placeord,
    write_u8(order_byte),
    write_u64_le(price),
    write_u64_le(amount),
    write_i64_le(expiry),
  ])
}

/// Build instruction data for cancel order
pub fn build_cancel_order(order_id: Int) -> BitArray {
  bit_array.concat([constants.disc_cancelord, write_u64_le(order_id)])
}

/// Build instruction data for fill order
pub fn build_fill_order(order_id: Int) -> BitArray {
  bit_array.concat([constants.disc_fillord, write_u64_le(order_id)])
}

// ============================================================================
// Concentrated Liquidity Instructions
// ============================================================================

/// Build instruction data for initialize CL pool
pub fn build_init_cl_pool() -> BitArray {
  constants.disc_initclpl
}

/// Build instruction data for CL mint (add liquidity to range)
pub fn build_cl_mint(
  tick_lower: Int,
  tick_upper: Int,
  amount0: Int,
  amount1: Int,
  min_lp: Int,
) -> BitArray {
  bit_array.concat([
    constants.disc_clmint,
    write_i64_le(tick_lower),
    write_i64_le(tick_upper),
    write_u64_le(amount0),
    write_u64_le(amount1),
    write_u64_le(min_lp),
  ])
}

/// Build instruction data for CL burn (remove liquidity from range)
pub fn build_cl_burn(liquidity: Int, min0: Int, min1: Int) -> BitArray {
  bit_array.concat([
    constants.disc_clburn,
    write_u64_le(liquidity),
    write_u64_le(min0),
    write_u64_le(min1),
  ])
}

/// Build instruction data for CL collect fees
pub fn build_cl_collect() -> BitArray {
  constants.disc_clcollect
}

/// Build instruction data for CL swap
pub fn build_cl_swap(
  amount_in: Int,
  min_out: Int,
  sqrt_price_limit: Int,
) -> BitArray {
  bit_array.concat([
    constants.disc_clswap,
    write_u64_le(amount_in),
    write_u64_le(min_out),
    write_u64_le(sqrt_price_limit),
  ])
}

// ============================================================================
// Flash Loan Instructions
// ============================================================================

/// Build instruction data for flash loan
pub fn build_flash_loan(amount0: Int, amount1: Int) -> BitArray {
  bit_array.concat([
    constants.disc_flashloan,
    write_u64_le(amount0),
    write_u64_le(amount1),
  ])
}

/// Build instruction data for flash loan repay
pub fn build_flash_repay() -> BitArray {
  constants.disc_flashrepy
}

// ============================================================================
// Multi-hop Instructions
// ============================================================================

/// Build instruction data for multi-hop swap
pub fn build_multihop(
  amount_in: Int,
  min_out: Int,
  deadline: Int,
  directions: List(Int),
) -> BitArray {
  let n_hops = list.length(directions)
  let direction_bytes = list.map(directions, write_u8)
  bit_array.concat([
    constants.disc_multihop,
    write_u64_le(amount_in),
    write_u64_le(min_out),
    write_i64_le(deadline),
    write_u8(n_hops),
    ..direction_bytes
  ])
}

// ============================================================================
// ML Brain Instructions
// ============================================================================

/// Build instruction data for initialize ML brain
pub fn build_init_ml(
  is_stable: Bool,
  min_fee: Int,
  max_fee: Int,
  fee_step: Int,
  min_amp: Int,
  max_amp: Int,
  amp_step: Int,
) -> BitArray {
  bit_array.concat([
    constants.disc_initml,
    write_bool(is_stable),
    write_u64_le(min_fee),
    write_u64_le(max_fee),
    write_u64_le(fee_step),
    write_u64_le(min_amp),
    write_u64_le(max_amp),
    write_u64_le(amp_step),
  ])
}

/// Build instruction data for configure ML brain
pub fn build_config_ml(enabled: Bool, auto_apply: Bool) -> BitArray {
  bit_array.concat([
    constants.disc_cfgml,
    write_bool(enabled),
    write_bool(auto_apply),
  ])
}

/// Build instruction data for train ML brain
pub fn build_train_ml() -> BitArray {
  constants.disc_trainml
}

/// Build instruction data for apply ML action
pub fn build_apply_ml(action: Int) -> BitArray {
  bit_array.concat([constants.disc_applyml, write_u8(action)])
}

/// Build instruction data for log ML state
pub fn build_log_ml() -> BitArray {
  constants.disc_logml
}

// ============================================================================
// Transfer Hook Instructions
// ============================================================================

/// Build instruction data for transfer hook execute
pub fn build_transfer_hook_execute() -> BitArray {
  constants.disc_th_exec
}

/// Build instruction data for transfer hook init
pub fn build_transfer_hook_init() -> BitArray {
  constants.disc_th_init
}
