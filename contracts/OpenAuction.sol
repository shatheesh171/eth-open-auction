// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract OpenAuction {
    address payable public beneficiary;
    uint public auctionEndTime;

    //Current state of auction
    address public highestBidder;
    uint public highestBid;

    //Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    //Set to true at end, disallows any changes
    //By default initialized to false
    bool ended;

    //Events emmited on changes
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /// Auction has already ended
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid
    error BidNotHighEnough(uint highestBid);
    /// The auction has not ended yet
    error AuctionNotYetEnded();
    /// The fuction auctionEnd has already been called
    error AuctionEndAlreadyCalled();

    /// Create a simple auction with bidding time in seconds and beneficiary address
    constructor(uint biddingTime, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    /// Bid on auction with value sent together with this transaction. 
    /// Value will only be refunded if auction is not won
    function bid() external payable {
        //Revert call if bidding period is over
        // if (block.timestamp > auctionEndTime)
        //     revert AuctionAlreadyEnded();
        require(block.timestamp<auctionEndTime,"Auction already ended");

        // If bid is not higer, send the ether back
        // if (msg.value<=highestBid)
        //     revert BidNotHighEnough(highestBid);
        require(msg.value>highestBid,"Bid not high enough");

        // When more than highestBid comes, put the old bids in array to be withdrawn
        if (highestBid!=0){
            // Safer to let recipients withdraw money themselves
            pendingReturns[highestBidder] += highestBid; 
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(highestBidder, highestBid);
        
    }

    /// Withdraw a bid that was overbid
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount>0) {
            // Important to set to zero, because recipent can call function again as part of 
            // recieving call before `send` returns
            pendingReturns[msg.sender] = 0;


            // If amount not sent then re add to pendingReturns array
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender]=amount;
                return false;
            }
        }
        return true;
    }

    /// End auction and send highest bid to beneficiary
    function auctionEnd() external {

        // 1. Conditions
        if (block.timestamp<auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder,highestBid);

        //3. Interaction
        beneficiary.transfer(highestBid);        
    }
}