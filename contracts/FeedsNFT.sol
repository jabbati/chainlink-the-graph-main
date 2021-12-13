// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";

contract FeedsNFT is ERC721, Ownable {
    uint256 public tokenCounter;
    string public lowImageURI;
    string public highImageURI;

    mapping(uint256 => int) public tokenIdToHighValues;
    AggregatorV3Interface internal priceFeed;
    event CreatedFeedsNFT(uint256 indexed tokenId, int highValue);

    constructor(
        address _priceFeedAddress
    ) ERC721("Chainlink Feeds NFT", "CFN")
        public
    {
        tokenCounter = 0;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function addLowURI(string memory _svgLowURI) public onlyOwner {
        lowImageURI = _svgLowURI;
    }   

    function addHighURI(string memory _svgHighURI) public onlyOwner {
        highImageURI = _svgHighURI;
    }
// jsa addLow/High SVG puts the Base64 encoded .svg into a string in memory so it can become the On-Chain URI !!
    function addLowSVG(string memory _svgLowRaw) public onlyOwner {
        string memory svgURI = svgToImageURI(_svgLowRaw);
        addLowURI(svgURI);
    }

    function addHighSVG(string memory _svgHighRaw) public onlyOwner {
        string memory svgURI = svgToImageURI(_svgHighRaw);
        addHighURI(svgURI);
    }

    function create(int highValue) public {
        tokenIdToHighValues[tokenCounter] = highValue;
        emit CreatedFeedsNFT(tokenCounter, highValue);
        _safeMint(msg.sender, tokenCounter);
        tokenCounter = tokenCounter + 1;
    }
    // You could also just upload the raw SVG and have solildity convert it!
    // jsa - this is the super cool part - the image is actually ON the ETH Chain (not on a peertopeer like IPFS) done by using Base64 coding
    // the URI IS the actual SVG!! "Base64.encode..." turns it into ASCII ?
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        // example:
        // '<svg width="500" height="500" viewBox="0 0 285 350" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="black" d="M150,0,L75,200,L225,200,Z"></path></svg>'
        // would return ""
        string memory baseURL = "data:image/svg+xml;base64,"; // string 1 the URL start...
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));  // strng 2 the .svg as string
        return string(abi.encodePacked(baseURL,svgBase64Encoded));   // jsa - return the previous two strings "put together" - on chain image data - could mean more GAS :(
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        (,int price,,,)= priceFeed.latestRoundData();   // check to see if price is up and swap images based on feed from Off-Chain "AggregatorV3" contract jsa
        string memory imageURI = lowImageURI;           // Off-Chain means no GAS :)
        if (price >= tokenIdToHighValues[tokenId]){
            imageURI = highImageURI;
        }

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Chainlink Feeds NFT", // You can add whatever name here
                                '", "description":"An NFT that changes based on the Chainlink Feed", "attributes":"", "image":"',imageURI,'"}'
                            )
                        )
                    )
                )
            );
    /* The string returned is the TokenURI() Metadata format: jsa - SEE https://betterprogramming.pub/how-to-create-nfts-with-solidity-4fa1398eb70a
        {
        "name": "The Chainlink Elf",    
     "description": "Inspiring, Based, Mythical, Oracle loving creature. Leading the new world and helping teach about superior digital agreements. Also is good with a bow!",    
      "image": "https://ipfs.io/ipfs/QmTgqnhFBMkfT9s8PHKcdXBn1f5bG3Q5hmBaR4U6hoTvb1?filename=Chainlink_Elf.png",    
       "attributes": 
        [
           {
           "trait_type": "Strength",            
            "value": 84        
          }
         ]
       }
    */
    }
}
