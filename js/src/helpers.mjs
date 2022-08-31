import { utils } from "ethers";
import { Contract } from "starknet";

/**
 * @param {import("starknet").Provider} provider 
 * @param {string} artifact 
 * @param {string[]} args 
 * @returns {Promise<import("starknet").Contract>}
 */
export const deploy = async (provider, artifact, args) => {
  const ctc = await provider.deployContract({
    contract: artifact,
    constructorCalldata: args
  });

  console.log(`Deployment tx: ${ctc.transaction_hash}`);
  await provider.waitForTransaction(ctc.transaction_hash)
  if (ctc.address === undefined)
    throw new Error("Address undefined");

  return new Contract(JSON.parse(artifact).abi, ctc.address)
}

/**
 * @param {import("starknet").Provider} provider 
 * @param {import("starknet").Account} account 
 * @param {{
 *  contractAddress: string,
 *  entrypoint: string,
 *  calldata: string[]
 * }} executeArgs 
 */
export const execute = async (provider, account, executeArgs) => {
  const MAX_TX_FEE = utils.parseEther("0.1").toString(); // wei

  const txData = await account.execute(executeArgs, null, {
    maxFee: MAX_TX_FEE
  });

  console.log(`Executing ${txData.transaction_hash}`)
  await provider.waitForTransaction(txData.transaction_hash)
  console.log(`Done`);
}

/**
 * @param {string} str 
 * @returns {string}
 */
export const strToFelt = (str) => {
  const strB = Buffer.from(str)
  return strB.reduce((memo, byte) => {
    memo += byte.toString(16)
    return memo
  }, '0x');
}

/**
 * 
 * @param {import("ethers").BigNumber} bn 
 * @returns { [string, string] }
 */
export const bnToUint256 = (bn) => [String(bn), "0"]
