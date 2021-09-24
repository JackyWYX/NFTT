// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// licence granter
contract Licence is ERC721 {
    IERC721 public immutable token;
    uint256 public immutable tokenId;
    bytes32[] public contents;
    address public granter;
    modifier onlyOwner() {
        require(token.ownerOf(tokenId) == msg.sender, "onlyOwner");
        _;
    }
    struct license {
        // Info about original token (IP token)
        address origTokenContract;
        uint256 origTokenId;
        address granter;
        // Info about derived token
        address derivTokenContract;
        uint256 derivTokenId;
        address grantee;
        // Legal terms about usage of intellectual property
        string term;
    }

    constructor(IERC721 _token, uint256 _tokenId) ERC721("Licence", "licence") {
        //super(ERC721)("Licence", "licence");
        token = _token;
        tokenId = _tokenId;
    }

    function newContent(bytes calldata content) external onlyOwner {
        contents.push(keccak256(content));
    }

    function mint(
        address to,
        uint224 _tokenId,
        uint32 contentId
    ) external onlyOwner {
        ERC721._mint(to, uint256(_tokenId) | (uint256(contentId) << 224));
    }
}


contract IPFactory {
    mapping(address => mapping(uint256 => Licence)) public licences; // IERC721=>tokenid=>Licence
    Service[] public services;

    function createLicence(IERC721 token, uint256 tokenId) external {
        bytes32 salt = keccak256(abi.encodePacked(token, tokenId));
        licences[address(token)][tokenId] = new Licence{salt: salt}(
            token,
            tokenId
        );
    }

    function createService(string calldata _name, string calldata _symbol)
        external
    {
        bytes32 salt = bytes32(uint256(uint160(msg.sender)));
        services.push(new Service{salt: salt}(_name, _symbol));
    }
}

contract Service is ERC721, Ownable {
    enum Status {
        NONE,
        PENDING,
        DELIVERY,
        ACCEPTED
    }
    mapping(bytes32 => Status) public requests;
    mapping(uint256 => Licence) public licences;
    event Request(
        IERC721 token,
        uint256 tokenId,
        address requester,
        uint256 amount,
        uint256 newTokenId
    );

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function requestToken(IERC721 token, uint256 tokenId) external payable {
        bytes32 reqHash = keccak256(
            abi.encodePacked(token, tokenId, msg.sender, msg.value)
        );
        require(requests[reqHash] == Status.NONE, "onlyNone");
        requests[reqHash] = Status.PENDING;
        emit Request(token, tokenId, msg.sender, msg.value, uint256(reqHash));
    }

    function mint(
        IERC721 token,
        uint256 tokenId,
        uint256 value
    ) external {
        bytes32 reqHash = keccak256(
            abi.encodePacked(token, tokenId, msg.sender, value)
        );
        require(requests[reqHash] == Status.PENDING, "onlyPending");
        requests[reqHash] = Status.ACCEPTED;
        ERC721._mint(msg.sender, uint256(reqHash));
        payable(owner()).transfer(value);
    }

    function bindLicence(Licence licence, uint256 tokenId) external {
        require(requests[bytes32(tokenId)] == Status.ACCEPTED, "onlyAccepted");
        require(ERC721.ownerOf(tokenId) == msg.sender, "onlyTokenOwner");
        licence.transferFrom(msg.sender, address(this), tokenId);
        licences[tokenId] = licence;
    }
}
