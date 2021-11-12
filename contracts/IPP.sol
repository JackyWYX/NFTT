// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*
There is only one IPPool contract, one Licenser contract and one DerivativeFactory contract, but there will be multiple Derivative NFT contracts.
Licence tokenID is hash of licence;
Derivative NFT tokenId is incremental

# stake/unstake NFT to IP pool:
1. call IPPool.deposit(...)
2. call IPPool.withdraw(...)

# service register:
DerivativeFactory.register(...), this will deploy a new Derivative NFT.

# mint a Derivative NFT:
1. call DerivativeFactory.place_order(...), this step will generate a new order
2. call DerivativeFactory.add_delivery(...), this step will mint a new Derivative NFT, but hold by DerivativeFactory contract.
3. call DerivativeFactory.complete_order(...), this step will apply a license to Derivative NFT and transfer the NFT token to user.
*/

// licence granter
contract Licenser is ERC721("Licenser", "Licenser") {
    struct license {
        // Info about original token (IP token)
        address origTokenContract;
        uint256 origTokenId;
        address granter;
        // Info about derived token
        address derivTokenContract;
        uint256 derivTokenId;
        address grantee;
        uint256 timestamp;
        // Legal terms about usage of intellectual property
        string term;
    }
    mapping(uint256=>license) public licenses;
    mapping(address=>mapping(uint256=>uint256)) licenseOf;
    IPPool public immutable ippool;
    DerivativeFactory public immutable factory;
    constructor(IPPool _ippool) { 
        ippool = _ippool;
        factory = DerivativeFactory(msg.sender);
    }

    // mint a license owned by the derivative NFT pointing to the original one.
    // The legal terms are also input as an argument to justify the legal use of
    // NFT as intellectual property.
    // Caller must possess the original token.
    function mint(
        address _origContract,
        uint256 _origTokenId,
        address _grantee,
        address _derivContract,
        uint256 _derivTokenId,
        string calldata _terms
    ) external returns(uint256) {
        require(msg.sender == address(factory), "onlyFactory");
        license memory newLicense = license({
         origTokenContract:_origContract,
         origTokenId:_origTokenId,
         granter: ippool.tokenStaker(_origContract,_origTokenId),
        // Info about derived token
         derivTokenContract:_derivContract,
         grantee: _grantee,
         derivTokenId: _derivTokenId,
         timestamp: block.timestamp,
        // Legal terms about usage of intellectual property
         term:_terms
        });
        require(newLicense.granter != address(0), "Unauthorized IP");
        bytes32 licenseSig = keccak256(abi.encode(newLicense));
        licenses[uint256(licenseSig)] = newLicense;
        ERC721._mint(_derivContract, uint256(licenseSig)); // supper._mint()
        licenseOf[_derivContract][_derivTokenId] = uint256(licenseSig);
        return uint256(licenseSig);
    }

    // checkLicense returns the license with the given token
	function check_license(address _contract, uint256 _tokenId) external view returns (license memory) {
        return get(licenseOf[_contract][_tokenId]);
    }

     // get details about a license
	function get(uint256 licenseId) public view returns (license memory) {
        return licenses[licenseId];
    }
}

contract IPPool {
    struct Item {
        address token;
        uint256 tokenId;
    }
    mapping(address => mapping(uint256 => address)) public tokenStaker;
    mapping(address => mapping(uint256 => uint256)) public itemIndex;
    mapping(address => Item[]) public ownerItems;
    Item[] public items;
    
    function deposit(IERC721 token, uint256 tokenId) external {
        token.transferFrom(msg.sender, address(this), tokenId);
        tokenStaker[address(token)][tokenId] = msg.sender;
        items.push(Item(address(token), tokenId));
        itemIndex[address(token)][tokenId] = items.length - 1;
        ownerItems[msg.sender].push(Item({
            token: address(token),
            tokenId: tokenId
        }));
    }

    function withdraw(IERC721 token, uint256 tokenId) external {
        require(
            tokenStaker[address(token)][tokenId] == msg.sender,
            "onlyTokenOwner"
        );
        token.transferFrom(address(this), msg.sender, tokenId);
        uint256 index = itemIndex[address(token)][tokenId];
        delete tokenStaker[address(token)][tokenId];
        delete itemIndex[address(token)][tokenId];
        items[index] = items[items.length-1];
        items.pop();

        for (uint ii = 0; ii < ownerItems[msg.sender].length; ii++) {
            Item memory item = ownerItems[msg.sender][ii];
            if (item.token == address(token) && item.tokenId == tokenId) {
                // Found the item
                ownerItems[msg.sender][ii] = ownerItems[msg.sender][ownerItems[msg.sender].length-1];
                ownerItems[msg.sender].pop();
                break;
            }
        }
    }

    function get_items_by_owner(address owner) external view returns (Item[] memory) {
        return ownerItems[owner];
    }

	function get_items() external view returns (Item[] memory){
        return items;
    }

	function is_staked(address _contract, uint256 tokenId) external view returns (bool){
        return tokenStaker[_contract][tokenId] != address(0);
    }
}

contract Derivative is ERC721 {
    DerivativeFactory public factory;
    address public recipient;
    string public description;
    uint256 public totalSupply;
    mapping(uint256=>string) _tokenURI;

    constructor(address _recipient, string memory _name, string memory _symbol, string memory _description) ERC721(_name, _symbol) {
        recipient = _recipient;
        factory = DerivativeFactory(msg.sender);
        description = _description;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURI[tokenId];
    }

    // mint a derivative token with the license included
	function mint(address to, string calldata _URI) external returns(uint256) {
        require(msg.sender == address(factory), "onlyFactory");
        uint256 tokenId = totalSupply++;
        _tokenURI[tokenId] = _URI;
        ERC721._mint(to, tokenId);
        return tokenId;
    }
}

contract DerivativeFactory {
    Licenser public immutable licenser;
    IPPool public immutable ippool;
    Derivative[] public derivatives;
    constructor() {
        IPPool _ippool = new IPPool();
        Licenser _licenser = new Licenser(_ippool);
        ippool = _ippool;
        licenser = _licenser;
    }
    event Register(uint256 serviceId, Derivative derivative);
	function register(address recipient, string calldata name, string calldata symbol, string calldata description) external returns (Derivative) {
        bytes32 salt = keccak256(abi.encodePacked(name,symbol));
        Derivative derivative = new Derivative{salt:salt}(recipient, name, symbol, description);
        derivatives.push(derivative);
        emit Register(derivatives.length-1, derivative);
        return derivative;
    }
    enum Status {None, Pending, Deliveried, Completed, Cancelled }
    struct Order {
        address user;
        address tokenContract;
        uint256 tokenId;
        uint256 servicerId;
        address derivativeContract;
        uint256 derivativeTokenId;
        address licenser;
        uint256 licenseId;
        Status status;
    }
    Order[] public orders;
    event PlaceOrder(uint256 orderId, address user, address tokenContract, uint256 tokenId, uint256 servicerId);
    event AddDelivery(uint256 orderId, address derivativeContract, uint256 derivativeTokenId);
    event CompleteOrder(uint256 orderId, uint256 licenseId);
    event CancelOrder(uint256 orderId, Status preStatus);

    function place_order(address tokenContract, uint256 tokenId, uint256 servicerId) public {
        place_order_int(tokenContract, tokenId, servicerId);
    }

    function place_order_int(address tokenContract, uint256 tokenId, uint256 servicerId) internal returns (uint256) {
        Order memory order = Order({
            user: msg.sender,
            tokenContract: tokenContract,
            tokenId: tokenId,
            servicerId: servicerId,
         derivativeContract: address(derivatives[servicerId]),
         derivativeTokenId: 0,
         licenser: address(licenser),
         licenseId: 0,
            status: Status.Pending
        });
        orders.push(order);
        emit PlaceOrder(orders.length-1, msg.sender, tokenContract, tokenId, servicerId);
        return uint256(orders.length-1);
    }

    function add_delivery(uint256 orderId, string calldata _URI) public {
        Order storage order = orders[orderId];
        require(order.status == Status.Pending, "onlyPending");
        require(msg.sender == order.user, "only orderOwner");
        order.status = Status.Deliveried;
        Derivative derivative = derivatives[order.servicerId];
        uint256 derivativeTokenId = derivative.mint(address(this), _URI);
        order.derivativeContract = address(derivative);
        order.derivativeTokenId = derivativeTokenId;
        emit AddDelivery(orderId, address(derivative), derivativeTokenId);
    }

    function complete_order(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.status == Status.Deliveried, "onlyDeliveried");
        require(msg.sender == order.user, "only orderOwner");
        order.status = Status.Completed;

        Derivative derivative = Derivative(order.derivativeContract);
        derivative.transferFrom(address(this), order.user, order.derivativeTokenId);
        uint256 licenseId = licenser.mint(order.tokenContract, order.tokenId, order.user, address(derivative), order.derivativeTokenId, "");
        order.licenser = address(licenser);
        order.licenseId = licenseId;
        emit CompleteOrder(orderId, licenseId);
    }

    function cancel_order(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.status != Status.Completed, "order Completed");
        require(msg.sender == order.user, "only orderOwner");
        emit CancelOrder(orderId, order.status);
        order.status = Status.Cancelled;
    }

    function mint_full(address tokenContract, uint256 tokenId, uint256 servicerId, string calldata _URI) external {
        uint256 orderID = place_order_int(tokenContract, tokenId, servicerId);
        add_delivery(orderID, _URI);
        complete_order(orderID);
    }

    struct Service {
		address recipient;
		string  name;
        string  description;
	}

	function get_service(uint256 servicerId) public view returns (Service memory) {
        Derivative derivative = derivatives[servicerId];
        return Service({
            recipient: derivative.recipient(),
            name: derivative.name(),
            description: derivative.description()
        });
    }

	function list_service() external view returns (Service[] memory) {
        Service[] memory services = new Service[](derivatives.length);
        for(uint256 i = 0; i < services.length; i++) {
            services[i] = get_service(i);
        }
        return services;
    }

	function get_orders() external view returns (Order[] memory) {
        return orders;
    }
}
