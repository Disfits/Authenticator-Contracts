// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract AccountNFT is ERC721URIStorage {
    
    uint256 private tokenID;
    uint256 private projectID;
    
    //Mapping TokenID to ProjectID
    mapping(uint256=>uint256) TokenProject;
    
    // Mapping user address to their Project ID Array
    mapping(address=>uint256[]) UserProjects;
    
    //Project Info Array
    Project[] private Projects;
    
    address private _owner;
    
    struct Project{
        address projectOwner;
        uint256 projectID;
        uint256 NFTPrice;
        bool paused;
        uint256 NFTAmount;  
        uint256 amountSold;
    }
    
    event SignUp(address userAddress,uint256 projectId);
    event ProjectCreated(address creatorAddress,uint256 projectId,Project Info);
    
    constructor() ERC721("Authenticator Token","ATT") {
        tokenID = 1;
        projectID = 0;
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Accounts : Caller is not the owner");
        _;
    }
    
    modifier onlyProjectOwner(uint256 ProjectId){
        require(Projects[ProjectId].projectOwner == msg.sender,"Accounts : User is not project owner");
        _;
    }
    
    

    function signUp(string memory accountURI,uint256 ProjectId) external payable{
        require(projectExists(ProjectId),"Accounts : Project doesn't exist");
        require(Projects[ProjectId].amountSold < Projects[ProjectId].NFTAmount,"Accounts : NFT minting has reached limit set by owner");
        require(!Projects[ProjectId].paused,"Accounts : NFT minting paused by owner");
        require(msg.value == Projects[ProjectId].NFTPrice,"Accounts : Sent value not equal to set price");
        _safeMint(_msgSender(), tokenID);
        _setTokenURI(tokenID, accountURI);
        TokenProject[tokenID] = ProjectId;
        Projects[ProjectId].amountSold += 1;
        tokenID = tokenID + 1;
        emit SignUp(msg.sender,ProjectId);
    }
    
    //Checks if sender is ATT Token owner and token belongs to this project
    function signIn(uint256 ProjectID) external view returns(bool,string memory)
    {       
        uint256 tokenCount = balanceOf(msg.sender);
        require(tokenCount!=0,"Accounts : User doesn't have ATT");
        
        uint256 tokenNum;
        
        for(tokenNum = 1;tokenNum < tokenID;tokenNum++){
            if(ownerOf(tokenNum) == msg.sender && ProjectID == TokenProject[tokenNum]){
                    return (true,tokenURI(tokenNum));
            }
        }
        return (false,"null");
    }
    
    
    
    //Returns Project ID of the token
    function tokenProject(uint tokenId) public view returns(uint256){
        require(_exists(tokenId),"Token does not exists");
        return TokenProject[tokenId];
    }
    
    //Get project ID of all user's projects
    function getUserProjects() external view returns(uint256[] memory){
        return UserProjects[msg.sender];
    }
    
    
    //Get info of all user's projects
    function getAllUserProjectInfo() external view returns(Project[] memory){
        uint256 projectLength = UserProjects[msg.sender].length;
        Project[] memory userProjects = new Project[](projectLength);
        uint256 j;
        for (j=0;j<projectLength;j++){
            userProjects[j] = getProjectInfo(UserProjects[msg.sender][j]);
        }
        return userProjects;
        
    }
    
    //Get info of a project using project ID
    function getProjectInfo(uint256 projectId) public view returns(Project memory){
        return Projects[projectId];
    }
    
    //Create a new project
    function createProject(uint256 price,bool paused,uint256 amount) external {
        Project memory newProject;
        newProject.projectOwner = msg.sender;
        newProject.projectID = projectID;
        newProject.NFTPrice = price;
        newProject.paused = paused;
        newProject.NFTAmount = amount;
        newProject.amountSold = 0;
        Projects.push(newProject);
    
        UserProjects[msg.sender].push(projectID);
        emit ProjectCreated(msg.sender,projectID,newProject);
        projectID += 1;
    }
    
    function projectExists(uint256 projectId) internal view returns(bool) {
        
        if(projectId <= projectID){
            return true;
        }
        return false;
    }
    
    function changeProjectPrice(uint256 projectId,uint256 price) external onlyProjectOwner(projectId){
        require(projectExists(projectId),"Accounts : Project doesn't exist");
        Projects[projectId].NFTPrice = price;
    }
    
    function increateNFTAmount(uint256 projectId,uint256 amount) external onlyProjectOwner(projectId){
        require(projectExists(projectId),"Accounts : Project doesn't exist");
        require(Projects[projectId].NFTAmount < amount,"Accounts : amount can't be decreased");
        Projects[projectId].NFTAmount = amount;
    }
    
    function changePauseStatus(uint256 projectId,bool pause) external onlyProjectOwner(projectId){
        require(projectExists(projectId),"Accounts : Project doesn't exist");
        require(Projects[projectId].paused != pause,"Accounts : Paused status is already same");
        Projects[projectId].paused = pause;
    }

}
