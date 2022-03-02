// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;
    address payable public owner;

    // SVG parameters
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommands;
    uint256 public price;
    uint256 public size;
    string[] public pathCommands;
    string[] public colors;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event requestedRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId);
    event CreatedUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);

    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721 ("RandomSVG", "rsNFT")
    {
        fee = _fee;
        keyHash = _keyHash;
        tokenCounter = 0;
        price = 100000000000000000; // 0.1 ETH / MATIC / AVAX
        owner = payable(msg.sender);

        maxNumberOfPaths = 10;
        maxNumberOfPathCommands = 5;
        size = 500;
        pathCommands = ["M", "L"];
        colors = ["red", "blue", "green", "yellow", "black", "white"];

    }

     function create() public payable returns (bytes32 requestId) {
         require(msg.value >= price, "Need to send more ETH");
         requestId = requestRandomness(keyHash, fee);
         requestIdToSender[requestId] = msg.sender;
         uint256 tokenId = tokenCounter;
         requestIdToTokenId[requestId] = tokenId;
         tokenCounter += 1;
         emit requestedRandomSVG(requestId, tokenId);
         // get a random number
         // use that random number to generate some random SVG code
         // base64 encode the SVG code
         // get the tokenURI and mint the NFT

         // blockchains are deterministic
         // oracles, Chainlink VRF (chainlink verifiable randomness function)
     }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    function withdraw() public payable onlyOwner {
        owner.transfer(address(this).balance);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        // There is an issue!
        // The Chainlink VRF has a max gas of 200000 gas (computation units)
        // 2M gas
        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId);
        // generateRandomSVG
        tokenIdToRandomNumber[tokenId] = randomNumber;
        emit CreatedUnfinishedRandomSVG(tokenId, randomNumber);
    }

    function finishMint(uint256 _tokenId) public {
        // check to see if it's been minted and a random number is returned
        // generate some random SVG code
        // turn that into an image URI
        // use that imageURI to format into a tokenURI
        /*for (uint a; a < 10000; a++) {
            // to mint 10000
        }*/
        require(bytes(tokenURI(_tokenId)).length <= 0, "TokenURI is already all set!");
        require(tokenCounter > _tokenId, "TokenId has not been minted yet!");
        require(tokenIdToRandomNumber[_tokenId] > 0, "Need to wait for Chainlink VRF");
        uint256 randomNumber = tokenIdToRandomNumber[_tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(_tokenId, tokenURI);
        emit CreatedRandomSVG(_tokenId, svg);
    }

    function formatTokenURI (string memory _imageURI) public pure returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        return string(abi.encodePacked(
                baseURL,
                Base64.encode(
                    bytes(abi.encodePacked('{"name": "SVG NFT", "description": "An NFT based on SVG!", "attributes": "", "image": "', _imageURI, '"}')))));
    }

    function svgToImageURI(string memory _svg) public pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(_svg))));
        string memory imageURI = string(abi.encodePacked(baseURL, svgBase64Encoded));
        return imageURI;
    }

    function generateSVG(uint256 _randomNumber) public view returns (string memory finalSvg) {
        uint256 numberOfPaths = (_randomNumber % maxNumberOfPaths) + 1;
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='", uint2str(size), "' width='", uint2str(size), "'>" ));
        for (uint i = 0; i < numberOfPaths; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, i)));
            string memory pathSvg = generatePath(newRNG);
            finalSvg = string (abi.encodePacked(finalSvg, pathSvg));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generatePath(uint256 _randomNumber) public view returns (string memory pathSvg) {
        uint256 numberOfPathCommands = (_randomNumber % maxNumberOfPathCommands) + 1;
        pathSvg = "<path d='";
        for(uint i = 0; i < numberOfPathCommands; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, size + i)));
            string memory pathCommand = generatePathCommand(newRNG);
            pathSvg = string(abi.encodePacked(pathSvg, pathCommand));
        }
        string memory color = colors[_randomNumber % colors.length];
        pathSvg = string(abi.encodePacked(pathSvg, "' fill='transparent' stroke='", color, "'/>"));
    }

    function generatePathCommand(uint256 _randomNumber) public view returns (string memory pathCommand) {
        pathCommand = pathCommands[_randomNumber % pathCommands.length];
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, size * 2))) % size;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, size * 3))) % size;
        pathCommand = string(abi.encodePacked(pathCommand, " ", uint2str(parameterOne), " ", uint2str(parameterTwo)));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}