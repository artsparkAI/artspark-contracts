pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract SignedTokenVerifier {
    using ECDSAUpgradeable for bytes32;

    // TODO: Make everything private/internal except verifyToken
    address public _signer;

    event SignerUpdated(address newSigner);

    function _setSigner(address _newSigner) internal {
        _signer = _newSigner;
        emit SignerUpdated(_signer);
    }

    function _hash(string memory tokenUri)
        public 
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenUri));
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, signature) == _signer);
    }

    function _recover(bytes32 hash, bytes memory signature)
        public 
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function verifyToken(
        string calldata _tokenUri,
        bytes calldata _signature
    ) public view returns (bool) {
        return _verify(_hash(_tokenUri), _signature);
    }
}
