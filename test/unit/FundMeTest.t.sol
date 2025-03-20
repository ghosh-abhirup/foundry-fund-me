// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    

    function setUp() external {
        // fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollerIsFive() public view{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
        
    }

    function testIfOwner() public view{
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testFundFailsWithoutEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testUpdatingFundData( ) public {
        vm.prank(USER) ;

        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        assertEq(amountFunded, SEND_VALUE);
    }

    function testSavesFunder() public {
        vm.prank(USER) ;

        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);

        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER) ;
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        
        vm.expectRevert();
        vm.prank(USER) ;
        fundMe.withdraw();

    }

    function testWithdrawWithAsSingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance+startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawOfMultipleFunders() public funded {
        uint160 noOfFunders = 6;
        uint160 startingIndex = 1;

        for(uint160 i=startingIndex; i<noOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assertEq(address(fundMe).balance , 0);
        assertEq(startingFundMeBalance+startingOwnerBalance, fundMe.getOwner().balance);

    }
}