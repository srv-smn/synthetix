pragma solidity ^0.5.16;

// Inheritance
import "./MixinResolver.sol";

// Internal references
import "./interfaces/ILimitOrdersState.sol";
import "./interfaces/IAddressResolver.sol";


contract LimitOrdersState is MixinResolver {
    /* ========== STRUCTS ========== */

    struct LimitOrder {
        address submitter;
        bytes32 sourceCurrencyKey;
        uint256 sourceAmount;
        bytes32 destinationCurrencyKey;
        uint256 minDestinationAmount;
        uint256 weiDeposit;
        uint256 executionFee;
    }

    /* ========== STATE VARIABLES ========== */
    IAddressResolver public addressResolverProxy;
    bytes32 internal constant CONTRACT_LIMITORDERS = "LimitOrders";
    bytes32[24] private addressesToCache = [CONTRACT_LIMITORDERS];

    uint256 public latestID;
    mapping(uint256 => LimitOrder) public orders;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _resolver) public MixinResolver(_resolver, addressesToCache) {
        addressResolverProxy = IAddressResolver(_resolver);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function _limitOrders() internal view returns (address) {
        return addressResolverProxy.requireAndGetAddress(CONTRACT_LIMITORDERS, "Missing LimitOrders address");
    }

    function getLatestID() external view returns (uint) {
        return latestID;
    }

    function getOrder(uint _orderID)
        external
        view
        returns (
            address,
            bytes32,
            uint256,
            bytes32,
            uint256,
            uint256,
            uint256
        )
    {
        LimitOrder memory order = orders[_orderID];
        return (
            order.submitter,
            order.sourceCurrencyKey,
            order.sourceAmount,
            order.destinationCurrencyKey,
            order.minDestinationAmount,
            order.weiDeposit,
            order.executionFee
        );
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function storeOrder(
        address _submitter,
        bytes32 _sourceCurrencyKey,
        uint256 _sourceAmount,
        bytes32 _destinationCurrencyKey,
        uint256 _minDestinationAmount,
        uint256 _weiDeposit,
        uint256 _executionFee
    ) external payable onlyLimitOrders returns (uint) {
        latestID++;
        orders[latestID] = LimitOrder(
            _submitter,
            _sourceCurrencyKey,
            _sourceAmount,
            _destinationCurrencyKey,
            _minDestinationAmount,
            _weiDeposit,
            _executionFee
        );
        return latestID;
    }

    function deleteOrder(uint _orderID, address _submitter) external onlyLimitOrders returns (uint) {
        require(_orderID <= latestID, "Order does not exist");
        LimitOrder memory order = orders[_orderID];
        require(order.submitter == _submitter, "Sender must be the order submitter");
        uint refundAmount = order.weiDeposit;
        delete orders[_orderID];
        msg.sender.transfer(refundAmount);
        return refundAmount;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyLimitOrders {
        require(msg.sender == _limitOrders(), "Only the LimitOrders contract can perform this action");
        _;
    }
}
