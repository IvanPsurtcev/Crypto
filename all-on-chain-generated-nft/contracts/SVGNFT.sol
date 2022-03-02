// give the contract some SVG code
// output an NFT URI with this SVG code
// Storing all the NFT metadata on-chain

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

contract SVGNFT is ERC721URIStorage {
    uint256 public tokenCounter;
    event CreatedSVGNFT(uint256 indexed tokenId, string tokenURI);

    constructor() ERC721 ("SVG NFT", "svgNFT") {
        tokenCounter = 0;
    }

    function create(string memory _svg) public {
        _safeMint(msg.sender, tokenCounter);
        string memory imageURI = svgToImageURI(_svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(tokenCounter, tokenURI);
        emit CreatedSVGNFT(tokenCounter, tokenURI);
        tokenCounter += 1;
    }

    function svgToImageURI(string memory _svg) public pure returns (string memory) {
        // <svg xmlns="http://www.w3.org/2000/svg" height="210" width="400"> <path d="M150 0 L75 200 L225 200 Z" /> </svg>
        // data:image/svg+xml;base64,<Base65-encoding>
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(_svg))));
        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
        // data:image/svg+xml;base64,URI
        return imageURI;
    }

    function formatTokenURI (string memory _imageURI) public pure returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        return string(abi.encodePacked(
            baseURL,
            Base64.encode(
                bytes(abi.encodePacked('{"name": "SVG NFT", "description": "An NFT based on SVG!", "attributes": "", "image": "', _imageURI, '"}')))));
    }
}