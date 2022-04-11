// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
  @title MetaBound LootBox

  @notice The MetaBound Private/Presale Loot Box contract implements the
  ERC1155 multi-token standard to allow for the minting of 8 different
  LootBox NFTs

  @author Castle Team
 */
contract MBLOOTBOX is ERC1155, AccessControl, Pausable, ERC1155Burnable, ERC1155Supply {

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

// add the two state variables to your contract
// specify the owner
// added a true false flag that will be used to indicate if the tokens are tradable

    address owner;
    bool public transferable = false;

//Payable team accounts
    address addA;
    address addB;
    address addC;
    address addD;
    uint256 addAN = 50;
    uint256 addBN = 20;
    uint256 addCN = 20;
    uint256 addDN = 10;

  //  mapping (uint256 => ) mintedSupply; //not sure if this will work or not
  // mapping (uint256 => Box[]) mappedBoxes;

  

    enum Level {
        BASIC,
        BASICPLUS,
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM,
        EMERALD,
        DIAMOND
    }

    Level public level;
    
    struct Box {
        uint256 id;
        Level level;
        string name;
        uint256 mintedSupply; //added this to allow for tracking from 0
        uint256 supply;
        uint256 price;
    }

    

    Box[] public boxes;

    Box public BASIC = Box(100, Level.BASIC, "BASIC", 0, 300, 0.5 ether);
    Box public BASICPLUS = Box(200, Level.BASICPLUS, "BASIC PLUS", 0, 150, 1 ether);
    Box public BRONZE = Box(300, Level.BRONZE, "BRONZE", 0, 50, 2.5 ether);
    Box public SILVER = Box(400, Level.SILVER, "SILVER", 0, 25, 5 ether);
    Box public GOLD = Box(500, Level.GOLD, "GOLD", 0, 10, 10 ether);
    Box public PLATINUM = Box(600, Level.PLATINUM, "PLATINUM", 0, 5, 20 ether);
    Box public EMERALD = Box(700, Level.EMERALD, "EMERALD", 0, 3, 40 ether);
    Box public DIAMOND = Box(800, Level.DIAMOND, "DIAMOND", 0, 1, 80 ether);

//   // what we want 
//   mappedBoxes[100] = Box(100, Level.BASIC, "BASIC", 300, 0.5 ether);
//   mappedBoxes[200] = Box(200, Level.BASICPLUS, "BASIC PLUS", 150, 1 ether);

constructor() 
        ERC1155("MetaBound LootBox Private Sale") {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(URI_SETTER_ROLE, msg.sender);
            _grantRole(PAUSER_ROLE, msg.sender);
            _grantRole(MINTER_ROLE, msg.sender);
            addA = msg.sender;
            addB = msg.sender;
            addC = msg.sender;
            addD = msg.sender;
            boxes.push(BASIC);
            boxes.push(BASICPLUS);
            boxes.push(BRONZE);
            boxes.push(SILVER);
            boxes.push(GOLD);
            boxes.push(PLATINUM);
            boxes.push(EMERALD);
            boxes.push(DIAMOND);
    }
  
  // function updateBox(uint256 _id, string _name, uint256 _minted, uint256 _supply, uint256 _price) public memory onlyRole() {
  //     Box storage box = getBoxById(_id);

  //     box.name = _name;
  //     box.mintedSupply = _minted;
  //     box.supply = _supply;
  //     box.price = _price;

  //     //mappedBoxes.push(_id) -1;
  //   }


  function getBoxes() external view returns(Box[] memory) {
      return boxes;
    }

  /*
  * return: [box, box, box, box] || []
  */
  function getBoxesBoughtByOwner(address wallet) external view returns(Box[] memory) {
    Box[] memory ownedBoxes = new Box[](boxes.length);

    for (uint256 i = 0; i < boxes.length; i++) {
      Box memory boxInLoop = boxes[i];
      if(balanceOf(wallet, boxInLoop.id) > 0) {
        ownedBoxes[i] = boxInLoop;
      }
    }

    return ownedBoxes;    
  }
  
    function getBoxById(uint256 boxId) internal view returns(Box memory) {
        Box memory foundBox;
        for(uint256 i = 0;i<boxes.length;i++) {
          Box memory loopBox = boxes[i];
  
          if(loopBox.id == boxId) {
            foundBox = loopBox;
            break;
          }
        }
      return foundBox;
    }

    function incrementMintedSupplyById(uint256 boxId) public {
      uint256 num;
      if (boxId == 100) {
        num = 0;
      } else {
        num = boxId / 100 - 1;
      }

      boxes[boxId].mintedSupply = totalSupply(num);
    }

  function hasMintedNft(address _address, uint256 lootBoxId) public view returns(bool) {
    return balanceOf(_address, lootBoxId) > 0;
  }

//Mint function   
/*
* Front end state:
*   - User has selected 1 or multiple boxes on the frontend and clicked mint
*
mintMultple (ids[]) {
  if ids is empty (fail, fatal)
  has wallet bought everything (fail, fatal)
  does msg.value have zero money (fail, fatal)

  loop the ids [101, 201{x}, 301]
    is the id a valid nft id (fail, continue)
    is there enough of a supply to buy one (fail, continue)
    has the wallet minted this box (continue)
    increment a price with the box price
    flag this box to be buyable
  end loop

  buyable = [101, 301]
  price = 10

  has the wallet got enough money (fail, fatal)
  create an amount array where each element is [1] for bulk mint

  call the IR1152 bulk mint function
}
*
*/ 

function mintMultipleBoxes(uint256[] memory ids)
        payable
        public
    {

      require(ids.length > 0, 'You arent trying to mint anything');
      // does msg.value have zero money (fail, fatal)
      require(msg.value > 0, "You're a poor Bitch");
      
      // How much this costs
      uint256 _mintRateTotal;
      uint256 _validNftCounter = 0;

      Box[] memory validBoxes = new Box[](boxes.length);

      for (uint256 i = 0; i < ids.length; i++) {
        // If the array passed looks like [4,2]
        // then pickedNftIndex for i = 0 would be 4
        // then pickedNftIndex for i = 1 would be 2
        
        Box memory loopBox = getBoxById(ids[i]);
        //if(!loopBox) {
        //  continue;
        //  }

        if(hasMintedNft(msg.sender, loopBox.id)) {
          continue;
        }

        if(loopBox.supply < 1) {
          continue;
        }
            
        // Calculates final price based on all box costs added together
        _mintRateTotal += loopBox.price;
        
        // add the index (i) to an array of valid nfts for this investor
        validBoxes[_validNftCounter] = loopBox;
        
        // sets each found valid Box to total amount of 1
        // amounts[i] = 1;
        _validNftCounter++;
        
      }        

      require(_validNftCounter > 0, 'No valid NFTs to mint');
      
      
      // Ensure the investor is sending enough 'currency' to trigger the mint
      require(msg.value >= _mintRateTotal, "You havent supplied enough BNB to mint the lootboxes");

      // Now that we have determined what nfts are valid
      // setup an amounts array that will be set to 1 and used
      // in the batch mint function
      uint256[] memory amounts = new uint[](_validNftCounter);
      for(uint256 x  = 0;x<(_validNftCounter);x++) {
        amounts[x] = 1;

        // // Add minted nfts to the boxId from the Box array **PANDY LOOK HERE**
        boxes[x].mintedSupply++;
      }
      
      // Remember when we created the validNfts array?
      // well we forced it to be a set size on creation
      // but we might not actually need all the entries in this array 
      // so we have to now trim / clean the array to only return 
      // the values we want, i.e. indexes with a 1 as it's value. 
      uint256[] memory cleanValidNfts = new uint[](_validNftCounter);
      
      for(uint256 y=0;y<(_validNftCounter);y++){
        cleanValidNfts[y] = validBoxes[y].id;
      }

      // This should only MINT valid nfts
        _mintBatch(msg.sender, cleanValidNfts, amounts, "");

      
    }

    function setNum(uint256 _addAN, uint256 _addBN, uint256 _addCN, uint256 _addDN) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require((_addAN + _addBN + _addCN + _addDN) >= 100, "Total must equal 100 or less" );
        addAN = _addAN;
        addBN = _addBN;
        addCN = _addCN;
        addDN = _addDN;
    }

    function setAddress(address _addAA, address _addBA, address _addCA, address _addDA) external onlyRole(DEFAULT_ADMIN_ROLE) {
      addA = _addAA;
      addB = _addBA;
      addC = _addCA;
      addD = _addDA;
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        
      uint256 contractBalance = address(this).balance;
      uint256  addANp = (contractBalance * addAN) / 100;
      uint256  addBNp = (contractBalance * addBN) / 100;
      uint256  addCNp = (contractBalance * addCN) / 100;
      uint256  addDNp = (contractBalance * addDN) / 100;

      (bool hs, ) = payable(addA).call{value: addANp}("");
      (hs, ) = payable(addB).call{value: addBNp}("");
      (hs, ) = payable(addC).call{value: addCNp}("");
      (hs, ) = payable(addD).call{value: addDNp}("");
    require(hs);
    }

    function withdrawAll() public onlyRole(DEFAULT_ADMIN_ROLE) {
      require(payable(msg.sender).send(address(this).balance));
    }

// add two function modifiers
// a modifier to check the owner of the contract
// a modifier to determine if the transferable flag is true of false
    modifier onlyOwner() {
         require(msg.sender == owner, 'Not Owner');
         _;
    }
    modifier istransferable() {
        require(transferable==false, 'Can Not Trade');
         _;
    }

// Prevent Transfers

    // function safeTransferFrom(address _to, uint256 _id, uint256 _amount) public override(ERC1155, ERC1155Supply) {
    //   if (msg.sender != DEFAULT_ADMIN_ROLE) {
    //       require(!transferable, "Transferring of Lootboxes is not available");
    //     }
    //   else{ (msg.sender = DEFAULT_ADMIN_ROLE);
    //     }
    //   super.safeTransferFrom(msg.sender, _to, _id, _amount, "");
    // }

// Standard Call functions for ERC1155

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
      require(!transferable, "Transferring of Lootboxes is not available");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    

}

