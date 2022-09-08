// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// With this "The UbiquiStick" NFT contract you can :
// - get all ERC721 functionnality https://eips.ethereum.org/EIPS/eip-721
//   - including check that someone as a NFT of the collection with « balanceOf »
//   - including check who is TokenID owner with « ownerOf »
//   - including optional ERC721Metadata
//     but without metadata JSON schema
//     with 3 types of NFTs : standard, gold and invisible, each one having same metadata
//     with 3 different tokenURIs
//   - including optional ERC721Enumerable
// - get you NFT listed on OpenSea (on mainnet or matic only)
// - allow NFT owner to burn it’s own NFT
// - allow one owner (deployer at start) to change tokenURIs (setTokenURI), and change minter (setMinter) and transfer it's owner role to someone else
// - allow one minter to mint NFT (safeMint)

contract TheUbiquityStick is ERC721, ERC721Burnable, ERC721Enumerable, Ownable {
  uint256 public tokenIdNext = 1;

  address public minter;

  string private _tokenURI;
  uint256 private constant STANDARD_TYPE = 0;

  string private _goldTokenURI;
  mapping(uint256 => bool) public gold;
  uint256 private constant GOLD_FREQ = 64;
  uint256 private constant GOLD_TYPE = 1;

  string private _invisibleTokenURI;
  uint256 private constant INVISIBLE_TOKEN_ID = 42;
  uint256 private constant INVISIBLE_TYPE = 2;

  modifier onlyMinter() {
    require(msg.sender == minter, "Not minter");
    _;
  }

  constructor() ERC721("The UbiquiStick", "KEY") {
    setMinter(msg.sender);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory uri) {
    require(_exists(tokenId), "Nonexistent token");
    return gold[tokenId] ? _goldTokenURI : (tokenId == INVISIBLE_TOKEN_ID ? _invisibleTokenURI : _tokenURI);
  }

  function setTokenURI(uint256 ntype, string memory tokenURI_) public onlyMinter {
    if (ntype == STANDARD_TYPE) {
      _tokenURI = tokenURI_;
    } else if (ntype == GOLD_TYPE) {
      _goldTokenURI = tokenURI_;
    } else if (ntype == INVISIBLE_TYPE) {
      _invisibleTokenURI = tokenURI_;
    }
  }

  function setMinter(address minter_) public onlyOwner {
    minter = minter_;
  }

  function safeMint(address to) public onlyMinter {
    uint256 tokenId = tokenIdNext;
    tokenIdNext += 1;

    // Gold one
    if (random() % uint256(GOLD_FREQ) == 0) {
      if (tokenId != INVISIBLE_TOKEN_ID) gold[tokenId] = true;
    }
    _safeMint(to, tokenId);
  }

  function batchSafeMint(address to, uint256 count) public onlyMinter {
    for (uint256 i = 0; i < count; i++) {
      safeMint(to);
    }
  }

  function random() private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, tokenIdNext)));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
