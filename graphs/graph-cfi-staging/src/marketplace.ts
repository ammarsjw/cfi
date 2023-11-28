import { store } from "@graphprotocol/graph-ts"

import {
    AuctionAcceptBid as AuctionAcceptBidEvent,
    AuctionBid as AuctionBidEvent,
    AuctionCancelBid as AuctionCancelBidEvent,
    EndSale as EndSaleEvent,
    SaleBuy as SaleBuyEvent,
    StartSale as StartSaleEvent,
    UpdateAllowedToken as UpdateAllowedTokenEvent,
    UpdateListing as UpdateListingEvent,
    UpdateTreasuryWallet as UpdateTreasuryWalletEvent
} from "../generated/Marketplace/Marketplace"

import {
    AuctionAcceptBid,
    AuctionBid,
    AuctionCancelBid,
    EndSale,
    SaleBuy,
    StartSale,
    UpdateAllowedToken,
    UpdateListing,
    UpdateTreasuryWallet,
    Bid,
    Sale
} from "../generated/schema"

import { BIGINT_ZERO, BYTES_ZERO } from "./utils/constants"

export function handleAuctionAcceptBid(event: AuctionAcceptBidEvent): void {
    let entity = new AuctionAcceptBid(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.collection = event.params.collection
    entity.tokenId = event.params.tokenId
    entity.index = event.params.index
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()

    // {Bid} entity id.
    let bidEntityId =
        event.params.collection.toHexString()
        .concat("-")
        .concat(event.params.tokenId.toString())
        .concat("-")
        .concat(event.params.index.toString())

    // Load {Bid} entity.
    let buyer = BYTES_ZERO
    let amountToken = BIGINT_ZERO
    let bidEntity = Bid.load(bidEntityId)

    if (bidEntity) {
        buyer = bidEntity.bidder
        amountToken = bidEntity.amountToken
    }

    // Load {UpdateListing} entity.
    let token = BYTES_ZERO
    let updateListingEntity = UpdateListing.load(event.params.collection.toString())

    if (updateListingEntity) {
        token = updateListingEntity.token
    }

    // Create {Sale} entity.
    let saleEntity = new Sale(event.transaction.hash.concatI32(event.logIndex.toI32()))
    saleEntity.collection = event.params.collection
    saleEntity.tokenId = event.params.tokenId
    saleEntity.buyer = buyer
    saleEntity.amountToken = amountToken
    saleEntity.token = token
    saleEntity.blockNumber = event.block.number
    saleEntity.blockTimestamp = event.block.timestamp
    saleEntity.transactionHash = event.transaction.hash
    saleEntity.save()

    // Remove {Bid} entity.
    store.remove("Bid", bidEntityId)
}

export function handleAuctionBid(event: AuctionBidEvent): void {
    let entity = new AuctionBid(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.collection = event.params.collection
    entity.tokenId = event.params.tokenId
    entity.index = event.params.index
    entity.bidder = event.params.bidder
    entity.amountToken = event.params.amountToken
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()

    // Create {Bid} entity.
    let bidEntity = new Bid(
        event.params.collection.toHexString()
            .concat("-")
            .concat(event.params.tokenId.toString())
            .concat("-")
            .concat(event.params.index.toString())
    )
    bidEntity.collection = event.params.collection
    bidEntity.tokenId = event.params.tokenId
    bidEntity.index = event.params.index
    bidEntity.bidder = event.params.bidder
    bidEntity.amountToken = event.params.amountToken
    bidEntity.blockNumber = event.block.number
    bidEntity.blockTimestamp = event.block.timestamp
    bidEntity.transactionHash = event.transaction.hash
    bidEntity.save()
}

export function handleAuctionCancelBid(event: AuctionCancelBidEvent): void {
    let entity = new AuctionCancelBid(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.collection = event.params.collection
    entity.tokenId = event.params.tokenId
    entity.index = event.params.index
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()

    // Remove {Bid} entity.
    let bidEntityId = event.params.collection.toHexString()
        .concat("-")
        .concat(event.params.tokenId.toString())
        .concat("-")
        .concat(event.params.index.toString())

    store.remove("Bid", bidEntityId)
}

export function handleEndSale(event: EndSaleEvent): void {
    let entity = new EndSale(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.collection = event.params.collection
    entity.tokenId = event.params.tokenId
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()
}

export function handleSaleBuy(event: SaleBuyEvent): void {
    let entity = new SaleBuy(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.collection = event.params.collection
    entity.tokenId = event.params.tokenId
    entity.buyer = event.params.buyer
    entity.amountToken = event.params.amountToken
    entity.token = event.params.token
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()

    // Create {Sale} entity.
    let saleEntity = new Sale(event.transaction.hash.concatI32(event.logIndex.toI32()))
    saleEntity.collection = event.params.collection
    saleEntity.tokenId = event.params.tokenId
    saleEntity.buyer = event.params.buyer
    saleEntity.amountToken = event.params.amountToken
    saleEntity.token = event.params.token
    saleEntity.blockNumber = event.block.number
    saleEntity.blockTimestamp = event.block.timestamp
    saleEntity.transactionHash = event.transaction.hash
    saleEntity.save()
}

export function handleStartSale(event: StartSaleEvent): void {
    let entity = new StartSale(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.collection = event.params.collection
    entity.tokenId = event.params.tokenId
    entity.startTime = event.params.startTime
    entity.endTime = event.params.endTime
    entity.duration = event.params.duration
    entity.price = event.params.price
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()
}

export function handleUpdateAllowedToken(event: UpdateAllowedTokenEvent): void {
    let entity = new UpdateAllowedToken(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.token = event.params.token
    entity.priceFeed = event.params.priceFeed
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()
}

export function handleUpdateListing(event: UpdateListingEvent): void {
    let entityId = event.params.collection.toString()
    let entity = UpdateListing.load(entityId)

    if (entity) {
        entity = updateListing(entity, event)
        entity.save()
    } else {
        let entity = new UpdateListing(entityId)
        entity = updateListing(entity, event)
        entity.save()
    }
}

function updateListing(entity: UpdateListing, event: UpdateListingEvent): UpdateListing {
    entity.collection = event.params.collection
    entity.startTime = event.params.startTime
    entity.token = event.params.token
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    return entity
}

export function handleUpdateTreasuryWallet(
    event: UpdateTreasuryWalletEvent
): void {
    let entity = new UpdateTreasuryWallet(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.newTreasuryWallet = event.params.newTreasuryWallet
    entity.oldTreasuryWallet = event.params.oldTreasuryWallet
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.save()
}

// TODO add null BigInt, Bytes in utils constant, import here and use accordingly