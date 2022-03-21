pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./SignedTokenVerifier.sol";
import "./math/BancorFormula.sol";
import "erc721a/contracts/ERC721AUpgradeable.sol";


contract Artspark is Initializable, OwnableUpgradeable, ERC721AUpgradeable, SignedTokenVerifier, BancorFormula, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    /*
    reserve ratio, represented in ppm, 1-1000000
    1/3 corresponds to y= multiple * x^2
    1/2 corresponds to y= multiple * x
    2/3 corresponds to y= multiple * x^1/2
    */
    uint32 public reserveRatio;
    uint256 internal reserve;
    uint256 public mintFee;
    uint256 public burnFee;

    //this lets you look up a token by the uri 
    mapping (bytes32 => uint256) public uriToTokenId;
    mapping (uint256 => string) public tokenIdToUri;


    function initialize(string memory _name, string memory _symbol, uint32 _reserveRatio, uint256 _reserveInit, address _signer) public initializer {
        __Ownable_init();
        __ERC721A_init(_name, _symbol);
        __BancorFormula_init();
        __ReentrancyGuard_init();
        reserveRatio = _reserveRatio;
        reserve = _reserveInit;
        _safeMint(_msgSender(), 1);
        _setSigner(_signer);
        _baseTokenURI = "https://artspark.mypinata.cloud/ipfs/";
    }

    function mint(string[] calldata tokenUris,  bytes[] calldata signatures) external payable {
        uint256 quantity = tokenUris.length;
        for (uint256 i; i < quantity; i++) {
            bytes32 tokenHash = _hash(tokenUris[i]);
            uint256 tokenId   = uriToTokenId[tokenHash];

            bool unmintedOrBurned = tokenId == 0 || _ownerships[tokenId].burned;
            bool validSignature = verifyToken(tokenUris[i], signatures[i]);
            require(unmintedOrBurned && validSignature, "Not a valid token");

            uriToTokenId[tokenHash] = _currentIndex.add(i);
            tokenIdToUri[_currentIndex.add(i)] = tokenUris[i];
        }

        (uint price, uint fee) = mintPrice(quantity);
        _safeMint(_msgSender(), quantity);

        receiveValue(price.add(fee));
        reserve = reserve.add(price);
    }

    function burn(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            TokenOwnership memory prevOwnership = ownershipOf(tokenIds[i]);

            bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
                isApprovedForAll(prevOwnership.addr, _msgSender()) ||
                getApproved(tokenIds[i]) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

            delete uriToTokenId[_hash(tokenIdToUri[tokenIds[i]])];
            delete tokenIdToUri[tokenIds[i]];
        }

        (uint refund, uint fee) = burnRefund(tokenIds.length);
        _burn(_msgSender(), tokenIds);
        reserve = reserve.sub(refund);
        payable(_msgSender()).transfer(refund.sub(fee));
    }

    function receiveValue(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            // refund excess ETH
            payable(_msgSender()).transfer(msg.value.sub(price));
        }
    }

    function tokenIds(string[] calldata tokenUris) external view returns (uint[] memory tokenIds) {
        uint[] memory _tokenIds = new uint[](tokenUris.length);
        for (uint i =0; i < tokenUris.length; i++) {
            bytes32 tokenHash = _hash(tokenUris[i]);
            _tokenIds[i] = uriToTokenId[tokenHash];
        }
        return _tokenIds;
    }

    function mintPrice(uint _numTokens) public view returns (uint amount, uint fee) {
        uint _price = fundCost(totalSupply(), reserve, reserveRatio, _numTokens);
        uint _fee = _price.div(10000).mul(mintFee);
        return (_price, _fee);
    }

    function burnRefund(uint _numTokens) public view returns (uint amount, uint fee) {
        uint _refund = saleTargetAmount(totalSupply(), reserve, reserveRatio, _numTokens);
        uint _fee = _refund.div(10000).mul(burnFee);
        return (_refund, _fee);
    }

    string private _baseTokenURI;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory uri) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenIdToUri[tokenId])) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setSigner(address _newSigner) external onlyOwner {
        _setSigner(_newSigner);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
    }

    // In units of 1/10000
    function setFees(uint256 _mintFee, uint256 _burnFee) external onlyOwner {
        mintFee = _mintFee;
        burnFee = _burnFee;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = _msgSender().call{value: address(this).balance.sub(reserve)}("");
        require(success, "Transfer failed.");
    }


    function ownershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
      return ownershipOf(tokenId);
    }

}
