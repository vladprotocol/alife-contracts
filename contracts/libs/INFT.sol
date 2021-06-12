// SPDX-License-Identifier: MIT
/**
Copyright 2021 <bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.

// 2021 - bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep

**/

pragma solidity ^0.6.12;

interface INFT {
    function setNftName(uint8 _nftId, string calldata _name) external;
    function mint(address _to, string calldata _tokenURI, uint8 _nftId) external returns (uint256);
    function getNftId(uint256 _tokenId) external view returns (uint8);
    function burn(uint256 _tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view virtual override returns (address);
}
