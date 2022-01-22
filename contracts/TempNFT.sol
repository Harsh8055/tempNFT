//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract TempNFT {
    // Create Collateral based NFT Renting/Borrowing
    NFTs[] public totalNftAvailable;
    
    // States of NFT - Available For Renting, Borrowed
    enum State {
        Available,
        Borrowed,
        Delisted
         }
    
    struct NFTLender {
        // string username;
        address payable ownerAddress;
        NFTs[] rentedNFTs;
        uint walletBalance;
    }

    struct NFTs {
        uint nftid; // per user id
        uint globalID; // global id
        uint hourlyRate; 
        uint dailyRate; 
        uint tokenID; 
        address owner;
        uint maxBorrowTime; // In Days
        address NFTaddress; 
        State stateOfNFT;
        uint typeOfNft;
        uint minimumCollateral; // user will input x , which will be a number greater than 1 and Floorprice*X will be set as minimum collatoral 
    }


    struct borrower {
        uint NFTGlobalID;
        address payable borrowerAddress; 
        address currentBorrowedNFT;
        uint collateralPaid;
        uint deadline; 
        string borrowType; // hourly or daily
        uint borrowedFor;  // how much hours or days
        uint walletBalance;
    }


   //A registry of NFT available For Renting, owner -> mapped to array of Address (NFT Address)
    mapping(address=>address[]) NFTRegistry;

    // 
    mapping(address=> NFTLender) lenderDetails; // adddress of lender mapped to 
    mapping(address=> borrower) borrowerDetails; // adddress of lender mapped to 
    

    // a few modifiers 
    modifier onlyOwnerRent(address _addressOfNft) {
      require(IERC721(_addressOfNft).balanceOf(msg.sender) != 0 || IERC721(_addressOfNft).balanceOf(msg.sender) != 0, "only owner can rent their NFT");
      _;
   }
    modifier onlyLender(address _addressOfNft,  uint _id ) {
      require(lenderDetails[msg.sender].rentedNFTs[_id].NFTaddress == _addressOfNft, "you are not the owner");
      _;
   }
    modifier Available(address _addressOfNft, uint _id) {
      require( lenderDetails[msg.sender].rentedNFTs[_id].stateOfNFT == State.Available, "NFt not available");
      _;
   }
    modifier Borrowed(address _addressOfNft, uint _id) {
      require( lenderDetails[msg.sender].rentedNFTs[_id].stateOfNFT == State.Borrowed, "NFt not available");
      _;
   }

   

    
    
    // Create A Dealer Function

    function rentNFT(address _nft, uint _hourlyRate, uint _dailyRate, uint _maxBorrowTimeInDays, uint _minCollateral, uint _tokenId) external onlyOwnerRent(_nft) {
     NFTLender memory nftOwner;
     nftOwner.ownerAddress = payable(msg.sender);
    
     NFTs memory newNFT;
     newNFT.hourlyRate = _hourlyRate;
     newNFT.dailyRate = _dailyRate;
     newNFT.maxBorrowTime = _maxBorrowTimeInDays;
     newNFT.minimumCollateral = _minCollateral;
     newNFT.NFTaddress = _nft; 
     newNFT.NFTaddress = _nft; 
     newNFT.tokenID = _tokenId; 
     newNFT.stateOfNFT = State.Available; 
     newNFT.nftid = newNFT.nftid;
     newNFT.globalID = totalNftAvailable.length;
     newNFT.owner = msg.sender;
     nftOwner.rentedNFTs[nftOwner.rentedNFTs.length] = newNFT;
     lenderDetails[msg.sender] = nftOwner;
     if( IERC721(_nft).balanceOf(msg.sender) != 0) {
      newNFT.typeOfNft = 721;
      IERC721(_nft).approve(address(this), _tokenId);
      IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId );
      NFTRegistry[msg.sender].push(_nft);
      totalNftAvailable.push(newNFT);
     }
     else {
      newNFT.typeOfNft = 1155;
      IERC1155(_nft).setApprovalForAll(address(this), true);
      IERC1155(_nft).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "" );
      NFTRegistry[msg.sender].push(_nft);
      totalNftAvailable.push(newNFT);
     }
     

    }

    // identifier - if 0 means user wants to borrow on hourly basic, so time will be considered in hours, num will be how many hours
        //    - if 1 means num will be how many days

        

    function borrowNFT( address _owner, uint _id,  address _nft, uint identifier,  uint num, uint _time ) payable external Available(_owner, _id) {  
      require( borrowerDetails[msg.sender].borrowerAddress == address(0));
     if(num == 0){ // meaning borrower is borrowing in hours 
        require( msg.value >= lenderDetails[msg.sender].rentedNFTs[_id].minimumCollateral + num*lenderDetails[msg.sender].rentedNFTs[_id].hourlyRate);  
    
      if(lenderDetails[_owner].rentedNFTs[_id].typeOfNft == 721) {
        IERC721(_nft).approve(msg.sender, lenderDetails[_owner].rentedNFTs[_id].tokenID);
        IERC721(_nft).transferFrom(address(this), msg.sender, lenderDetails[msg.sender].rentedNFTs[_id].tokenID);

      }
      else {
      IERC1155(_nft).setApprovalForAll(msg.sender, true);
      IERC1155(_nft).safeTransferFrom(address(this), msg.sender,  lenderDetails[_owner].rentedNFTs[_id].tokenID, 1, "" );

      }
        borrowerDetails[msg.sender].borrowerAddress = payable(msg.sender);
        borrowerDetails[msg.sender].borrowType = "hourly";
        borrowerDetails[msg.sender].borrowedFor = num;
        borrowerDetails[msg.sender].currentBorrowedNFT = _nft;
        borrowerDetails[msg.sender].deadline = block.timestamp + num*60*60;
        borrowerDetails[msg.sender].collateralPaid =  lenderDetails[msg.sender].rentedNFTs[_id].minimumCollateral;
        borrowerDetails[msg.sender].NFTGlobalID = lenderDetails[_owner].rentedNFTs[_id].globalID;
      }
      else{ // meaning borrower is borrowing in hours 
        require( msg.value >= lenderDetails[_owner].rentedNFTs[_id].minimumCollateral + num*lenderDetails[msg.sender].rentedNFTs[_id].dailyRate);  
    
      if(lenderDetails[_owner].rentedNFTs[_id].typeOfNft == 721) {
        IERC721(_nft).approve(address(this),  lenderDetails[_owner].rentedNFTs[_id].tokenID);
        IERC721(_nft).transferFrom(address(this), msg.sender, lenderDetails[msg.sender].rentedNFTs[_id].tokenID);

      }
      else {
      IERC1155(_nft).setApprovalForAll(msg.sender, true);
      IERC1155(_nft).safeTransferFrom(address(this), msg.sender,  lenderDetails[_owner].rentedNFTs[_id].tokenID, 1, "" );

      }
        borrowerDetails[msg.sender].currentBorrowedNFT = _nft;
        borrowerDetails[msg.sender].borrowerAddress = payable(msg.sender);
        borrowerDetails[msg.sender].borrowType = "daily";
        borrowerDetails[msg.sender].borrowedFor = num;
        borrowerDetails[msg.sender].deadline = block.timestamp + num*60*60*24;
        borrowerDetails[msg.sender].collateralPaid =  lenderDetails[_owner].rentedNFTs[_id].minimumCollateral;
        borrowerDetails[msg.sender].NFTGlobalID = lenderDetails[_owner].rentedNFTs[_id].globalID;
       } 

       lenderDetails[_owner].rentedNFTs[_id].stateOfNFT == State.Borrowed;
      }

    
    function  returnNFT(address owner, address _nft, uint  _id) external Borrowed(_nft, _id) {

       require(borrowerDetails[msg.sender].currentBorrowedNFT == _nft, "You should have borrowed the nft to return");
       if(lenderDetails[owner].rentedNFTs[_id].typeOfNft == 721) {
        IERC721(_nft).approve(address(this),  lenderDetails[owner].rentedNFTs[_id].tokenID);
        IERC721(_nft).transferFrom( msg.sender, address(this), lenderDetails[msg.sender].rentedNFTs[_id].tokenID);

      }
      else {
      IERC1155(_nft).setApprovalForAll(address(this), true);
      IERC1155(_nft).safeTransferFrom(msg.sender,address(this), lenderDetails[owner].rentedNFTs[_id].tokenID, 1, "" );

      }

      lenderDetails[owner].rentedNFTs[_id].stateOfNFT == State.Available;
      borrowerDetails[msg.sender].currentBorrowedNFT == address(0);
    
       
       

      if(borrowerDetails[msg.sender].deadline< block.timestamp) {
        uint diff = (block.timestamp - borrowerDetails[msg.sender].deadline)/3600;
         uint amountToPay = borrowerDetails[msg.sender].collateralPaid - diff*lenderDetails[owner].rentedNFTs[_id].hourlyRate;
         payable(msg.sender).transfer(amountToPay);
      }

      else {
         payable(msg.sender).transfer(borrowerDetails[msg.sender].collateralPaid);
      }

        borrowerDetails[msg.sender].borrowType = "";
        borrowerDetails[msg.sender].borrowedFor = 0;
        borrowerDetails[msg.sender].deadline = 0;
        borrowerDetails[msg.sender].collateralPaid =  0;
        

    } 
     
    function deList(address _nft, uint _id) external onlyLender(_nft, _id){ 
      if(lenderDetails[msg.sender].rentedNFTs[_id].typeOfNft == 721) {
        IERC721(_nft).approve(msg.sender,  lenderDetails[msg.sender].rentedNFTs[_id].tokenID);
        IERC721(_nft).transferFrom(address(this), msg.sender, lenderDetails[msg.sender].rentedNFTs[_id].tokenID);

      }
      else {
      IERC1155(_nft).setApprovalForAll(msg.sender, true);
      IERC1155(_nft).safeTransferFrom(address(this),msg.sender, lenderDetails[msg.sender].rentedNFTs[_id].tokenID, 1, "" );

      }
      lenderDetails[msg.sender].rentedNFTs[_id].stateOfNFT == State.Delisted;


    }

  function getNftFromGlobalId(uint _globalId) view external returns(NFTs memory) {
    return totalNftAvailable[_globalId];

  }

  function getLender(address _owner) view external returns(NFTLender memory) {
    return  lenderDetails[_owner];
  }

  function getBorrowedNFT() view external returns(borrower memory) {
      if(borrowerDetails[msg.sender].currentBorrowedNFT == address(0)) {
      
      }
       else {
       return borrowerDetails[msg.sender];
       }
    }
  
     

}
