/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract SignatureVerifier {
  /**
   * @notice Recovers the address for an ECDSA signature and message hash, note that the hash is automatically prefixed with "\x19Ethereum Signed Message:\n32"
   * @return address The address that was used to sign the message
   */
  function recoverAddress (bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
    
    return ecrecover(prefixedHash, v, r, s);
  }

  
     /**
   * @notice Recovers the address for an ECDSA signature and message hash, note that the hash is automatically prefixed with "\x19Ethereum Signed Message:\n32"
   * @return address The address that was used to sign the message
   */
  function recoverAddress3 (bytes32 hash, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
    return ecrecover(hash, v, r, s);
  }

  
  /**
   * @notice Checks if the recovered address from an ECDSA signature is equal to the address `signer` provided.
   * @return valid Whether the provided address matches with the signature
   */
  function isValid (address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s) external pure returns (bool) {
    return recoverAddress(hash, v, r, s) == signer;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}