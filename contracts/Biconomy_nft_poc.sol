pragma solidity ^0.8.0;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import 'https://github.com/CrazyNFT/biconomy_nft_poc/blob/master/contracts/BaseRelayRecipient.sol';
contract Biconomy_nft_poc is ERC1155, Ownable, BaseRelayRecipient {

    // Hashes of NFT pictures on IPFS
    string[] public hashes;

    // Mapping for enforcing unique hashes
    mapping(string => bool) _hashExists;

    // Mapping from ipfs picture hash to NFT tokenID
    mapping (string => uint256) private _hashToken;

    event NFTMinted(address creator, uint256 tokenId);

    constructor() public ERC1155("https://exampleurl/tokenmetadata/{id}.json") {
      trustedForwarder = 0x4D373d1B9a0367219a5f6547B8DfaC39f846F6a9;
    }

    function setTrustedForwarder(address _trustedForwarder) public {
      trustedForwarder = _trustedForwarder;
    }


    /**
     * @notice Mints a new NFT
     * @param _hash IPFS picture hash of the NFT
     */
    function mint(string memory _hash) public {
        require(!_hashExists[_hash], "Token with this hash is already minted");

        hashes.push(_hash);
        uint256 _id = hashes.length - 1;
        _mint(_msgSender(), _id, 1, "");

        _hashExists[_hash] = true;
        _hashToken[_hash] = _id;

        emit NFTMinted(_msgSender(), _id);
    }

    /**
     * @notice Returns the TokenID of nft
     * @return tokenID of the nft
     */
    function getTokenID(string memory _hash) public view returns (uint256 tokenID) {
        return _hashToken[_hash];
    }

    /**
     * @notice Returns the number of minted nfts
     * @return count the number of nfts
     */
    function getNftCount() public view returns (uint256 count) {
        return hashes.length;
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
