#!/usr/bin/env node

const yargs = require('yargs/yargs')
const { hideBin } = require('yargs/helpers')
const fs = require('fs')
const path = require('path');

module.exports = {
    getArgv: function() {
        return yargs(hideBin(process.argv)).argv
    },
    createFile: function(filePath) {
        const dir = path.dirname(filePath)
        if (!fs.existsSync(dir)){
            fs.mkdirSync(dir, { recursive: true });
        }
        fs.closeSync(fs.openSync(filePath, 'w'));
    }
}
