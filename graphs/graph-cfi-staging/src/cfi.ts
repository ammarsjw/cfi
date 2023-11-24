import {
    SetBaseURI as SetBaseURIEvent
} from "../generated/CFI/CFI"

import {
    CFISetBaseURI
} from "../generated/schema"

export function handleSetBaseURI(event: SetBaseURIEvent): void {
    let entity = new CFISetBaseURI(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.newBaseURI = event.params.newBaseURI
    entity.oldBaseURI = event.params.oldBaseURI

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}
