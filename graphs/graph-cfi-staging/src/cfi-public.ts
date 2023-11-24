import {
    SetBaseURI as SetBaseURIEvent,
    SetTokenURI as SetTokenURIEvent,
    Tag as TagEvent
} from "../generated/CFIPublic/CFIPublic"

import {
    CFIPublicSetBaseURI,
    CFIPublicSetTokenURI,
    CFIPublicTag
} from "../generated/schema"

export function handleSetBaseURI(event: SetBaseURIEvent): void {
    let entity = new CFIPublicSetBaseURI(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.newBaseURI = event.params.newBaseURI
    entity.oldBaseURI = event.params.oldBaseURI

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleSetTokenURI(event: SetTokenURIEvent): void {
    let entity = new CFIPublicSetTokenURI(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.newTokenURI = event.params.newTokenURI
    entity.oldTokenURI = event.params.oldTokenURI

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleTag(event: TagEvent): void {
    let entity = new CFIPublicTag(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.tokenId = event.params.tokenId
    entity.tag = event.params.tag

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}
