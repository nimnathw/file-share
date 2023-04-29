// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ShareToken.sol";

contract ShareFiles {
    address owner;
    ShareToken token;

    struct Share {
        string decryptionKey;
        address contributor;
    }

    mapping(bytes32 => Share[]) shares;

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = ShareToken(_tokenAddress);
    }

    function shareFile(bytes32 ipfsHash, string memory decryptionKey) external {
        Share memory share = Share(decryptionKey, msg.sender);
        shares[ipfsHash].push(share);
        token.transfer(msg.sender, 1);
    }

    function getDecryptionKey(bytes32 ipfsHash) external {
        require(token.transferFrom(msg.sender, address(this), 1), "Token transfer failed");
        Share[] storage sharesArray = shares[ipfsHash];
        require(sharesArray.length > 0, "No decryption key found");
        string memory decryptionKey = sharesArray[sharesArray.length - 1].decryptionKey;
        address contributor = sharesArray[sharesArray.length - 1].contributor;
        require(contributor != msg.sender, "You cannot get the decryption key for your own share");
        sharesArray.pop();
        (bool success, ) = contributor.call(abi.encodeWithSignature("receiveDecryptionKey(string)", decryptionKey));
        require(success, "Decryption key delivery failed");
    }

    function withdrawTokens() external {
        require(msg.sender == owner, "Only owner can withdraw tokens");
        token.transfer(owner, token.balanceOf(address(this)));
    }
}
