import json, strutils
import core, utils
import response_type

export response_type

proc getJoinedComunities*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  let payload = %* []
  result = callPrivateRPC("joinedCommunities".prefix, payload)

proc getAllCommunities*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("communities".prefix)

proc joinCommunity*(communityId: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("joinCommunity".prefix, %*[communityId])

proc requestToJoinCommunity*(communityId: string, ensName: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("requestToJoinCommunity".prefix, %*[{
    "communityId": communityId,
    "ensName": ensName
  }])

proc myPendingRequestsToJoin*(): RpcResponse[JsonNode] {.raises: [Exception].} =
  result =  callPrivateRPC("myPendingRequestsToJoin".prefix)

proc leaveCommunity*(communityId: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("leaveCommunity".prefix, %*[communityId])

proc createCommunity*(
    name: string,
    description: string,
    access: int,
    ensOnly: bool,
    color: string,
    imageUrl: string,
    aX: int, aY: int, bX: int, bY: int
    ): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("createCommunity".prefix, %*[{
      # TODO this will need to be renamed membership (small m)
      "Membership": access,
      "name": name,
      "description": description,
      "ensOnly": ensOnly,
      "color": color,
      "image": imageUrl,
      "imageAx": aX,
      "imageAy": aY,
      "imageBx": bX,
      "imageBy": bY
    }])

proc createCommunityChannel*(
    communityId: string,
    name: string,
    description: string
    ): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("createCommunityChat".prefix, %*[
    communityId,
    {
      "permissions": {
        "access": 1 # TODO get this from user selected privacy setting
      },
      "identity": {
        "display_name": name,
        "description": description#,
        # "color": color#,
        # TODO add images once it is supported by Status-Go
        # "images": [
        #   {
        #     "payload": image,
        #     # TODO get that from an enum
        #     "image_type": 1 # 1 is a raw payload
        #   }
        # ]
      }
    }])

proc editCommunityChannel*(
    communityId: string,
    channelId: string,
    name: string,
    description: string,
    categoryId: string,
    position: int
    ): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("editCommunityChat".prefix, %*[
    communityId,
    channelId.replace(communityId, ""),
    {
      "permissions": {
        "access": 1 # TODO get this from user selected privacy setting
      },
      "identity": {
        "display_name": name,
        "description": description#,
        # "color": color#,
        # TODO add images once it is supported by Status-Go
        # "images": [
        #   {
        #     "payload": image,
        #     # TODO get that from an enum
        #     "image_type": 1 # 1 is a raw payload
        #   }
        # ]
      },
      "category_id": categoryId,
      "position": position
    }])

proc reorderCommunityChat*(
    communityId: string,
    categoryId: string,
    chatId: string,
    position: int
    ): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("reorderCommunityChat".prefix, %*[
    {
      "communityId": communityId,
      "categoryId": categoryId,
      "chatId": chatId,
      "position": position
    }])

proc deleteCommunityChat*(
    communityId: string,
    chatId: string
    ): RpcResponse[JsonNode] {.raises: [Exception].}  =
  result = callPrivateRPC("deleteCommunityChat".prefix, %*[communityId, chatId])

proc createCommunityCategory*(
    communityId: string,
    name: string,
    channels: seq[string]
    ): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("createCommunityCategory".prefix, %*[
    {
      "communityId": communityId,
      "categoryName": name,
      "chatIds": channels
    }])

proc editCommunityCategory*(
    communityId: string,
    categoryId: string,
    name: string,
    channels: seq[string]
    ): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("editCommunityCategory".prefix, %*[
    {
      "communityId": communityId,
      "categoryId": categoryId,
      "categoryName": name,
      "chatIds": channels
    }])

proc deleteCommunityCategory*(
    communityId: string,
    categoryId: string
    ): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("deleteCommunityCategory".prefix, %*[
    {
      "communityId": communityId,
      "categoryId": categoryId
    }])

proc requestCommunityInfo*(communityId: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("requestCommunityInfoFromMailserver".prefix, %*[communityId])

proc importCommunity*(communityKey: string): RpcResponse[JsonNode] {.raises: [Exception].} =
  result = callPrivateRPC("importCommunity".prefix, %*[communityKey])

proc exportCommunity*(communityId: string): RpcResponse[JsonNode] {.raises: [Exception].}  =
  result = callPrivateRPC("exportCommunity".prefix, %*[communityId])
