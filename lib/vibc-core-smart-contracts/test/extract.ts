import { describe, it } from 'mocha'
import { assert } from 'chai'
import os from 'os'
import path from 'path'
import fs from 'fs'
import { extractVibcCoreSmartContracts } from '../src/index'

function readdir(dir: string) {
  return fs
    .readdirSync(dir, { withFileTypes: true })
    .map((d) => {
      if (d.isDirectory()) return readdir(path.join(dir, d.name))
      return path.join(dir, d.name)
    })
    .flat()
}

describe('Extract API', function () {
  const tmpdir = fs.mkdtempSync(os.tmpdir() + path.sep)

  after(() => {
    fs.rmSync(tmpdir, { recursive: true, force: true })
  })

  it('extracted contracts match with the built artifacts', async function () {
    await extractVibcCoreSmartContracts(tmpdir)
    const contractsDir = path.join(__dirname, '..', 'artifacts', 'contracts')
    const expected = readdir(contractsDir).map((d: string) => d.replace(contractsDir, ''))
    const actual = readdir(tmpdir).map((d: string) => d.replace(tmpdir, ''))
    assert.deepEqual(actual, expected)
  })
})
