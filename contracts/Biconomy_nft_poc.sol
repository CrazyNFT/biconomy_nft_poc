pragma solidity ^0.8.0;
import 'https://github.com/CrazyNFT/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol';
import 'https://github.com/CrazyNFT/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import 'https://github.com/CrazyNFT/biconomy_nft_poc/blob/master/contracts/BaseRelayRecipient.sol';

contract Biconomy_nft_poc is ERC721, Ownable, BaseRelayRecipient {
        using Strings for uint256;

        // Optional mapping for token URIs
        mapping (uint256 => string) private _tokenURIs;
        // Base URI
        string private _baseURIextended;

        function setTrustedForwarder(address _trustedForwarder) public {
          trustedForwarder = _trustedForwarder;
        }


        constructor(string memory _name, string memory _symbol)
            ERC721(_name, _symbol)
        {
            
        }

        function setBaseURI(string memory baseURI_) external onlyOwner() {
            _baseURIextended = baseURI_;
        }

        function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
            require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
            _tokenURIs[tokenId] = _tokenURI;
        }

        function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
        }

        function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

            string memory _tokenURI = _tokenURIs[tokenId];
            string memory base = _baseURI();

            // If there is no base URI, return the token URI.
            if (bytes(base).length == 0) {
                return _tokenURI;
            }
            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            if (bytes(_tokenURI).length > 0) {
                return string(abi.encodePacked(base, _tokenURI));
            }
            // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
            return string(abi.encodePacked(base, tokenId.toString()));
        }


        function mint(
            address _to,
            uint256 _tokenId,
            string memory tokenURI_
        ) external onlyOwner() {
            _mint(_to, _tokenId);
            _setTokenURI(_tokenId, tokenURI_);
        }

    function versionRecipient() external override view returns (string memory) {
      return "V4";
    }
    function _msgSender() internal override(BaseRelayRecipient,Context) view returns (address sender) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20))) 
            }
        } else {
            return msg.sender;
        }
    }
      function _msgData() internal override(Context) view returns (bytes memory ret) {
          if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
              // At this point we know that the sender is a trusted forwarder,
              // we copy the msg.data , except the last 20 bytes (and update the total length)
              assembly {
                  let ptr := mload(0x40)
                  // copy only size-20 bytes
                  let size := sub(calldatasize(),20)
                  // structure RLP data as <offset> <length> <bytes>
                  mstore(ptr, 0x20)
                  mstore(add(ptr,32), size)
                  calldatacopy(add(ptr,64), 0, size)
                  return(ptr, add(size,64))
              }
          } else {
              return msg.data;
          }
      }


}
