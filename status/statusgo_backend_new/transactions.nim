import json, stint, chronicles, strutils

import ./core as core

type PendingTransactionType* {.pure.} = enum
  RegisterENS = "RegisterENS",
  SetPubKey = "SetPubKey",
  ReleaseENS = "ReleaseENS",
  BuyStickerPack = "BuyStickerPack"
  WalletTransfer = "WalletTransfer" 

proc checkRecentHistory*(addresses: seq[string]) {.raises: [Exception].} =
  let payload = %* [addresses]
  discard callPrivateRPC("wallet_checkRecentHistory", payload)

proc getTransfersByAddress*(address: string, toBlock: Uint256, limitAsHexWithoutLeadingZeros: string, 
  loadMore: bool = false): RpcResponse[JsonNode] {.raises: [Exception].} =
  let toBlockParsed = if not loadMore: newJNull() else: %("0x" & stint.toHex(toBlock))
    
  callPrivateRPC("wallet_getTransfersByAddress", %* [address, toBlockParsed, limitAsHexWithoutLeadingZeros, loadMore])
    
proc trackPendingTransaction*(hash: string, fromAddress: string, toAddress: string, trxType: PendingTransactionType, data: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* [{"hash": hash, "from": fromAddress, "to": toAddress, "type": $trxType, "additionalData": data, "data": "",  "value": 0, "timestamp": 0, "gasPrice": 0, "gasLimit": 0}]
  callPrivateRPC("wallet_storePendingTransaction", payload)