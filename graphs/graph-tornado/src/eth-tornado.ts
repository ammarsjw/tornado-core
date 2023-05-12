import {
  Deposit as DepositEvent,
  Transfer as TransferEvent,
  Withdrawal as WithdrawalEvent
} from "../generated/ETHTornado/ETHTornado"

import {
  Deposit,
  Transfer,
  Withdrawal
} from "../generated/schema"

export function handleDeposit(event: DepositEvent): void {
  let entity = new Deposit(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.commitment = event.params.commitment
  entity.leafIndex = event.params.leafIndex
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTransfer(event: TransferEvent): void {
  let entity = new Transfer(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.commitment = event.params.commitment
  entity.leafIndex = event.params.leafIndex
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleWithdrawal(event: WithdrawalEvent): void {
  let entity = new Withdrawal(event.transaction.hash.toHex() + '-' + event.logIndex.toString());

  // let result = contractsToInstances.get(event.address.toHexString()).split('-');

  entity.amount = "0.1";
  entity.currency = "eth";

  entity.to = event.params.to;
  entity.fee = event.params.fee;
  entity.index = event.logIndex;
  entity.blockNumber = event.block.number;
  entity.timestamp = event.block.timestamp;
  entity.nullifier = event.params.nullifierHash;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}