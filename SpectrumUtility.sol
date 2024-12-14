// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SpectrumUtility {
    function getGcd(uint256 a, uint256 b) public pure returns (uint256) {
        while (b != 0) {
            uint256 temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }

    function getAuth(uint256 p, uint256 q) public pure returns (uint256, uint256, uint256, uint256) {
        uint256 n = p * q;
        uint256 phi = (p - 1) * (q - 1);
        uint256 e = 2;
        while (e < phi) {
            if (getGcd(e, phi) == 1) break;
            e++;
        }
        uint256 d = 1;
        while (((d * e) % phi) != 1) {
            d++;
        }
        uint256 mesg = 19;
        uint256 c = modExp(mesg, e, n);
        return (n, d, mesg, c);
    }

    function modExp(uint256 base, uint256 exponent, uint256 modulus) public pure returns (uint256) {
        uint256 result = 1;
        base = base % modulus;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = (result * base) % modulus;
            }
            exponent = exponent >> 1;
            base = (base * base) % modulus;
        }
        return result;
    }
}