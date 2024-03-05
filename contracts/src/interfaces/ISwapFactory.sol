// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

interface ISwapHelperFactory {
    function createSwapHelper(address swapRouter) external returns (address swapHelper);

    function setOwner(address newOwner) external;
}