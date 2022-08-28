import { Account, Provider, ec } from "starknet"
import { readFileSync } from "fs"
import { utils, BigNumber } from "ethers"
import { EARLY_STARKERS_ARTIFACT, ERC20_ARTIFACT, ACCOUNT_ARTIFACT } from "./artifacts.mjs"
import { deploy, execute, strToFelt, bnToUint256 } from "./helpers.mjs"

import keys from "./account.mjs"
import { formatUnits, parseUnits } from "ethers/lib/utils.js"
const OWNER_KP = ec.getKeyPair(keys[0].privateKey)
const TEAM_KP = ec.getKeyPair(keys[1].privateKey)
const USER1_KP = ec.getKeyPair(keys[2].privateKey)
const USER2_KP = ec.getKeyPair(keys[3].privateKey)

////////////////////////////////////////////////////////////////////////////////
// Network Options and Constants
////////////////////////////////////////////////////////////////////////////////

const DEVNET_PROVIDER_OPTIONS = {
  baseUrl: 'http://127.0.0.1:5050/'
}

const TESTNET_PROVIDER_OPTIONS = {
  baseUrl: 'https://alpha4.starknet.io',
  feederGatewayUrl: 'feeder_gateway',
  gatewayUrl: 'gateway',
}

////////////////////////////////////////////////////////////////////////////////

const provider = new Provider(DEVNET_PROVIDER_OPTIONS);
const owner = new Account(provider, keys[0].address, OWNER_KP)
const team = new Account(provider, keys[1].address, TEAM_KP)
const user1 = new Account(provider, keys[2].address, USER1_KP)
const user2 = new Account(provider, keys[3].address, USER2_KP)

let erc20, earlyStarkers;

const prevDeployment = {}

async function main() {
  const beforeDeploy = Date.now();

  erc20 = prevDeployment.erc20 ?? await deploy(
    provider,
    ERC20_ARTIFACT,
    [
      strToFelt("TEST"),
      strToFelt("T"),
      18,
      ...bnToUint256(
        utils.parseUnits(String(10 ** 6), String(18))
      ),
      user1.address,
      owner.address
    ]
  );

  earlyStarkers = prevDeployment.es ?? await deploy(
    provider,
    EARLY_STARKERS_ARTIFACT,
    [
      owner.address,
      team.address
    ]
  );

  await execute(provider, owner, {
    contractAddress: earlyStarkers.address,
    entrypoint: "__t_set_eth_addr",
    calldata: [erc20.address]
  })

  console.log("Deployments - OK");
  console.log(`in ${(Date.now() - beforeDeploy) / 1000} seconds`);

  console.log({
    erc20: erc20.address,
    earlyStarkers: earlyStarkers.address
  });

  await testPublicMint();
  // await testName();
  await testBurn();
}

async function testPublicMint() {
  await expectRevert(async () => {
    await execute(provider, user1, {
      contractAddress: earlyStarkers.address,
      entrypoint: "public_mint",
      calldata: ["1"]
    });
  }, "Shouldn't mint before opening");

  const publicMintFee = parseUnits(String(1), String(17)).toString()

  await execute(provider, owner, {
    contractAddress: earlyStarkers.address,
    entrypoint: "start_public_mint",
    calldata: [publicMintFee]
  });
  console.log("start_public_mint - OK");

  await expectRevert(async () => {
    await execute(provider, user2, {
      contractAddress: earlyStarkers.address,
      entrypoint: "public_mint",
      calldata: ["2"]
    });
  }, "Shouldn't mint more than 1");

  await expectRevert(async () => {
    await execute(provider, user2, {
      contractAddress: earlyStarkers.address,
      entrypoint: "public_mint",
      calldata: ["1"]
    });
  }, "Shouldn't mint without tokens");

  await execute(provider, user1, {
    contractAddress: erc20.address,
    entrypoint: "transfer",
    calldata: [user2.address, publicMintFee, "0"]
  });
  console.log("user1 -> user2 transfer - OK");

  await execute(provider, user2, {
    contractAddress: erc20.address,
    entrypoint: "increaseAllowance",
    calldata: [earlyStarkers.address, publicMintFee, "0"]
  })

  const { result: allowanceResult } = await provider.callContract({
    contractAddress: erc20.address,
    entrypoint: "allowance",
    calldata: [
      BigNumber.from(user2.address).toString(),
      BigNumber.from(earlyStarkers.address).toString(),
    ]
  });
  assertEq(BigNumber.from(allowanceResult[0]).toString(), publicMintFee);
  console.log("increaseAllowance - OK");

  await execute(provider, user2, {
    contractAddress: earlyStarkers.address,
    entrypoint: "public_mint",
    calldata: ["1"]
  });
  console.log("public_mint - OK");

  const { result: nftBalanceResult } = await provider.callContract({
    contractAddress: earlyStarkers.address,
    entrypoint: "balanceOf",
    calldata: [BigNumber.from(user2.address).toString()]
  })
  assertEq(BigNumber.from(nftBalanceResult[0]).toString(), 1)
  console.log("public_mint Test - OK");
}

async function testWhitelistMint() {
  /**
   * @type {{
   *  proof: string[],
   *  root: string,
   *  leaf: string,
   *  false_leaf: string    
   * }}
   */
  const wl_merkle = JSON.parse(readFileSync("./proof.json", "utf-8"))

  // await expectRevert(async () => {
  //   await execute(provider, owner, {
  //     contractAddress: earlyStarkers.address,
  //     entrypoint: "wl_mint",
  //     calldata: [
  //       "1",
  //       wl_merkle.leaf,
  //       wl_merkle.proof.length + 1,
  //       ...wl_merkle.proof,
  //       wl_merkle.root
  //     ]
  //   })
  // }, "Shouldn't wl_mint before owner starts")

  const wlMintFee = parseUnits(String(1), String(17)).toString()

  await execute(provider, owner, {
    contractAddress: earlyStarkers.address,
    entrypoint: "start_wl_mint",
    calldata: [wlMintFee]
  })
  console.log('start_wl_mint - OK');

  await execute(provider, owner, {
    contractAddress: earlyStarkers.address,
    entrypoint: "change_wl_root",
    calldata: [wl_merkle.root]
  })
  console.log('change_wl_root - OK')

  // await expectRevert(async () => {
  //   await execute(provider, user, {
  //     contractAddress: earlyStarkers.address,
  //     entrypoint: "wl_mint",
  //     calldata: [
  //       "1",
  //       wl_merkle.leaf,
  //       wl_merkle.proof.length,
  //       ...wl_merkle.proof
  //     ]
  //   })
  // }, "Shouldn't wl_mint before allowance")

  await execute(provider, user1, {
    contractAddress: erc20.address,
    entrypoint: "increaseAllowance",
    calldata: [
      BigNumber.from(earlyStarkers.address).toString(),
      wlMintFee, "0"
    ]
  })

  const { result: allowanceResult } = await provider.callContract({
    contractAddress: erc20.address,
    entrypoint: "allowance",
    calldata: [
      BigNumber.from(user1.address).toString(),
      BigNumber.from(earlyStarkers.address).toString(),
    ]
  });
  console.log("increaseAllowance - OK", allowanceResult[0]);

  const { result: erc20BalanceResult } = await provider.callContract({
    contractAddress: erc20.address,
    entrypoint: "balanceOf",
    calldata: [BigNumber.from(user1.address).toString()]
  });
  console.log(formatUnits(BigNumber.from(erc20BalanceResult[0]), "18"));

  await execute(provider, user1, {
    contractAddress: earlyStarkers.address,
    entrypoint: "wl_mint",
    calldata: [
      "1",
      wl_merkle.leaf,
      wl_merkle.proof.length,
      ...wl_merkle.proof
    ]
  })
  console.log("wl_mint - OK");

  const { result: nftBalanceResult } = await provider.callContract({
    contractAddress: earlyStarkers.address,
    entrypoint: "balanceOf",
    calldata: [BigNumber.from(user1.address).toString()]
  })
  assertEq(BigNumber.from(nftBalanceResult[0]).toString(), 1)

  const { result: ownerResult } = await provider.callContract({
    contractAddress: earlyStarkers.address,
    entrypoint: "ownerOf",
    calldata: ["1", "0"]
  });
  assertEq(ownerResult[0].toLowerCase(), user2.address.toLowerCase())
}

async function testName() {
  await expectRevert(async () => {
    await execute(provider, user1, {
      contractAddress: earlyStarkers.address,
      entrypoint: "change_name",
      calldata: ["1", "0", strToFelt("Token Name")]
    })
  }, "Shouldn't change unonwed token")

  await expectRevert(async () => {
    await execute(provider, user2, {
      contractAddress: earlyStarkers.address,
      entrypoint: "change_star_wall_links",
      calldata: ["1", "0", "3", strToFelt("tw:zetsuboii"), strToFelt("gh:zetsuboii"), strToFelt("ens:zetsub0ii.eth")]
    })
  }, "Shouldn't change star wall before naming")

  await expectRevert(async () => {
    await execute(provider, user2, {
      contractAddress: earlyStarkers.address,
      entrypoint: "change_galactic_talks_links",
      calldata: ["1", "0", "2", strToFelt("hey"), strToFelt("hi")]
    })
  }, "Shouldn't change galactic talks before naming")

  const nameFee = parseUnits(String(2), String(17)).toString()

  await execute(provider, owner, {
    contractAddress: earlyStarkers.address,
    entrypoint: "change_name_price",
    calldata: [nameFee]
  })

  await expectRevert(async () => {
    await execute(provider, user1, {
      contractAddress: earlyStarkers.address,
      entrypoint: "change_name",
      calldata: ["1", "0", strToFelt("Token Name")]
    })
  }, "Shouldn't change name without paying fee")

  await execute(provider, user1, {
    contractAddress: erc20.address,
    entrypoint: "transfer",
    calldata: [user2.address, nameFee, "0"]
  });
  console.log("user1 -> user2 transfer - OK");

  await execute(provider, user2, {
    contractAddress: erc20.address,
    entrypoint: "increaseAllowance",
    calldata: [earlyStarkers.address, nameFee, "0"]
  })

  console.log("increaseAllowance - OK");

  await execute(provider, user2, {
    contractAddress: earlyStarkers.address,
    entrypoint: "change_name",
    calldata: ["1", "0", strToFelt("Token Name")]
  })
  console.log("change_name - OK");

  const { result: erc20BalanceResult } = await provider.callContract({
    contractAddress: erc20.address,
    entrypoint: "balanceOf",
    calldata: [ BigNumber.from(user2.address).toString() ]
  })
  assertEq(BigNumber.from(erc20BalanceResult[0]).toString(), "0")

  await expectRevert(async () => {
    await execute(provider, user2, {
      contractAddress: earlyStarkers.address,
      entrypoint: "change_name",
      calldata: ["1", "0", strToFelt("Token Name")]
    })
  }, "Shouldn't change name twice")

  const { result: nameResult } = await provider.callContract({
    contractAddress: earlyStarkers.address,
    entrypoint: "name_of",
    calldata: ["1", "0"]
  })
  assertEq(nameResult[0].toLowerCase(), strToFelt("Token Name").toLowerCase());

  await execute(provider, user2, {
    contractAddress: earlyStarkers.address,
    entrypoint: "change_star_wall_links",
    calldata: ["1", "0", "3", strToFelt("tw:zetsuboii"), strToFelt("gh:zetsuboii"), strToFelt("ens:zetsub0ii.eth")]
  })
  console.log("change_star_wall_links - OK");

  const { result: stResult } = await provider.callContract({
    contractAddress: earlyStarkers.address,
    entrypoint: "star_wall_links_of",
    calldata: ["1", "0"]
  });
  assertEq(BigNumber.from(stResult[0]).toString(), "3")
  assertEq(stResult[1].toLowerCase(), strToFelt("tw:zetsuboii").toLowerCase())
  assertEq(stResult[2].toLowerCase(), strToFelt("gh:zetsuboii").toLowerCase())
  assertEq(stResult[3].toLowerCase(), strToFelt("ens:zetsub0ii.eth").toLowerCase())

  await execute(provider, user2, {
    contractAddress: earlyStarkers.address,
    entrypoint: "change_galactic_talks_links",
    calldata: ["1", "0", "2", strToFelt("hey"), strToFelt("hi")]
  })
  console.log("change_galactic_talks_links - OK");

  const { result: gtResult } = await provider.callContract({
    contractAddress: earlyStarkers.address,
    entrypoint: "galactic_talks_links_of",
    calldata: ["1", "0"]
  });
  assertEq(BigNumber.from(gtResult[0]).toString(), "2")
  assertEq(gtResult[1].toLowerCase(), strToFelt("hey").toLowerCase())
  assertEq(gtResult[2].toLowerCase(), strToFelt("hi").toLowerCase())

  console.log("Name Test - OK");
}

async function testBurn() {
  await expectRevert(async () => {
    await execute(provider, user2, {
      contractAddress: earlyStarkers.address,
      entrypoint: "burn",
      calldata: ["1", "0"]
    });
  }, "Shouldn't burn while burning is not activated")

  await execute(provider, owner, {
    contractAddress: earlyStarkers.address,
    entrypoint: "enable_burn",
    calldata: []
  });
  console.log("enable_burn - OK");

  await execute(provider, user2, {
    contractAddress: earlyStarkers.address,
    entrypoint: "burn",
    calldata: ["1", "0"]
  });
  console.log("burn - OK");

  const { result: afterNftBalanceResult } = await provider.callContract({
    contractAddress: earlyStarkers.address,
    entrypoint: "balanceOf",
    calldata: [BigNumber.from(user2.address).toString()]
  })
  assertEq(BigNumber.from(afterNftBalanceResult[0]).toString(), "0")

  console.log("burn Test - OK");
}

async function expectRevert(fn, msg) {
  try {
    await fn();
    throw new Error("Expected revert: " + msg);
  } catch (e) {
    console.log("Got expected revert");
  }
}

function assertEq(a, b) {
  if (a != b) {
    throw new Error(`Assertion error, expected ${a} to be equal ${b}`);
  }
}

function assertNotEq(a, b) {
  if (a == b) {
    throw new Error(`Assertion error, expected ${a} to be not equal ${b}`);
  }
}

main()
  .then(() => { process.exit(0) })
  .catch(e => { console.log(e); process.exit(-1) })
