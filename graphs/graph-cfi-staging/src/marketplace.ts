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
    ActiveSale,
    BidHistory,
    SaleHistory
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

    // {BidHistory} entity id.
    let bidHistoryEntityId =
        event.params.collection.toHexString()
            .concat("-")
            .concat(event.params.tokenId.toString())
            .concat("-")
            .concat(event.params.index.toString())

    // Load {BidHistory} entity.
    let buyer = BYTES_ZERO
    let amountToken = BIGINT_ZERO
    let bidHistoryEntity = BidHistory.load(bidHistoryEntityId)

    if (bidHistoryEntity) {
        buyer = bidHistoryEntity.bidder
        amountToken = bidHistoryEntity.amountToken
    }

    // Load {UpdateListing} entity.
    let token = BYTES_ZERO
    let updateListingEntity = UpdateListing.load(event.params.collection.toString())

    if (updateListingEntity) {
        token = updateListingEntity.token
    }

    // Create {SaleHistory} entity.
    let saleHistoryEntity = new SaleHistory(event.transaction.hash.concatI32(event.logIndex.toI32()))
    saleHistoryEntity.collection = event.params.collection
    saleHistoryEntity.tokenId = event.params.tokenId
    saleHistoryEntity.buyer = buyer
    saleHistoryEntity.amountToken = amountToken
    saleHistoryEntity.token = token
    saleHistoryEntity.blockNumber = event.block.number
    saleHistoryEntity.blockTimestamp = event.block.timestamp
    saleHistoryEntity.transactionHash = event.transaction.hash
    saleHistoryEntity.save()

    // Remove {BidHistory} entity.
    store.remove("BidHistory", bidHistoryEntityId)
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

    // Create {BidHistory} entity.
    let bidHistoryEntity = new BidHistory(
        event.params.collection.toHexString()
            .concat("-")
            .concat(event.params.tokenId.toString())
            .concat("-")
            .concat(event.params.index.toString())
    )
    bidHistoryEntity.collection = event.params.collection
    bidHistoryEntity.tokenId = event.params.tokenId
    bidHistoryEntity.index = event.params.index
    bidHistoryEntity.bidder = event.params.bidder
    bidHistoryEntity.amountToken = event.params.amountToken
    bidHistoryEntity.blockNumber = event.block.number
    bidHistoryEntity.blockTimestamp = event.block.timestamp
    bidHistoryEntity.transactionHash = event.transaction.hash
    bidHistoryEntity.save()
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

    // Remove {BidHistory} entity.
    store.remove(
        "Bid",
        event.params.collection.toHexString()
            .concat("-")
            .concat(event.params.tokenId.toString())
            .concat("-")
            .concat(event.params.index.toString())
    )
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

    // Remove {ActiveSale} entity.
    store.remove(
        "ActiveSale",
        event.params.collection.toHexString()
            .concat("-")
            .concat(event.params.tokenId.toString())
    )
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

    // Remove {ActiveSale} entity.
    store.remove(
        "ActiveSale",
        event.params.collection.toHexString()
            .concat("-")
            .concat(event.params.tokenId.toString())
    )

    // Create {SaleHistory} entity.
    let saleHistoryEntity = new SaleHistory(event.transaction.hash.concatI32(event.logIndex.toI32()))
    saleHistoryEntity.collection = event.params.collection
    saleHistoryEntity.tokenId = event.params.tokenId
    saleHistoryEntity.buyer = event.params.buyer
    saleHistoryEntity.amountToken = event.params.amountToken
    saleHistoryEntity.token = event.params.token
    saleHistoryEntity.blockNumber = event.block.number
    saleHistoryEntity.blockTimestamp = event.block.timestamp
    saleHistoryEntity.transactionHash = event.transaction.hash
    saleHistoryEntity.save()
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

    // Create {ActiveSale} entity.
    let activeSaleEntity = new ActiveSale(
        event.params.collection.toHexString()
            .concat("-")
            .concat(event.params.tokenId.toString())
    )
    activeSaleEntity.collection = event.params.collection
    activeSaleEntity.tokenId = event.params.tokenId
    activeSaleEntity.startTime = event.params.startTime
    activeSaleEntity.endTime = event.params.endTime
    activeSaleEntity.duration = event.params.duration
    activeSaleEntity.price = event.params.price
    activeSaleEntity.blockNumber = event.block.number
    activeSaleEntity.blockTimestamp = event.block.timestamp
    activeSaleEntity.transactionHash = event.transaction.hash
    activeSaleEntity.save()
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