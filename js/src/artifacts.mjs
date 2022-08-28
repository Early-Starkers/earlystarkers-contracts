import { resolve, dirname } from 'path'
import { readFileSync } from "fs"
import { fileURLToPath } from 'url'

const readArtifact = (name) => readFileSync(
    resolve(
      dirname(fileURLToPath(import.meta.url)),
      "..",
      "artifacts",
      `${name}.txt`
    ),
    "utf-8"
  )

const EARLY_STARKERS_ARTIFACT = readArtifact("early_starkers")
const ERC20_ARTIFACT = readArtifact("erc20m")
const ACCOUNT_ARTIFACT = readArtifact("account")

export {
  ACCOUNT_ARTIFACT,
  EARLY_STARKERS_ARTIFACT,
  ERC20_ARTIFACT,
}