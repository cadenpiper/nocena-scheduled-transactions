transaction(blocks: UInt64) {
    prepare(signer: auth(Storage) &Account) {
        var i: UInt64 = 0
        while i < blocks {
            // This transaction advances one block each time it's executed
            i = i + 1
        }
        log("Advanced ".concat(blocks.toString()).concat(" blocks"))
    }
}
