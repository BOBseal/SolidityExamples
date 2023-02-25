//SPDX-License-Identifier : MIT
pragma solidity >=0.8.0;

contract Chat {
    struct user{
        string name;
        friend[] friendList;
        Blog[] blogList;
        Task[] taskList;
        Transactions[] transactionList;
    }
    struct friend{
        address pubKey;
        string  name;
    }
    struct Blog {
        uint ID;
        string title;
        string content;
        uint timestamp;
        uint likes;
    }
    struct message {
        address sender;
        uint timestamp;
        string msg;
    }

    struct AllUserStruct{
        string name;
        string nickName;
        address accountAddress;
    }
      struct Task{
        uint taskNo;
        string TitleTask;
        string Description;
        uint TaskCreatedAt;
        bool completed;
        uint TaskCompletedAt;
    }
    struct Transactions{
        uint transactionCounter;
        address to;
        address from;
        uint amount;
        string tagdescription;
        uint transactionTime;
        string transactionHash;
    }
    address payable owner;
     constructor() {
        owner = payable(msg.sender);
        IDCount = 1;
        TuskNum = 1;
    }
    AllUserStruct[] getAllUsers;
    uint transactionCounter;
    uint TuskNum;
    uint IDCount;
    mapping(address => user) userList;
    mapping(bytes32 => message[]) allMessages;
    mapping(bytes32 => bool) likedBlogs;


    function SendEth(address to , address from ,uint amount , string calldata tagdescription , string calldata transactionHash) external{
        require (checkUserExists(msg.sender), "Please Create an Account First");
        Transactions memory newTrans= Transactions(0 , to , from , amount , tagdescription , block.timestamp , transactionHash);
        transactionCounter ++ ;
        userList[msg.sender].transactionList.push(newTrans);
    }
    function getTransactions() external view returns(Transactions[] memory){
        require(checkUserExists(msg.sender), "Please Create an Account First");
        return userList[msg.sender].transactionList;
    }
    function addTask(string calldata TitleTask, string calldata Description) external{
         require (checkUserExists(msg.sender), "Please Create an Account First");
         require (bytes (TitleTask).length > 0 ,"Title Must be There");
         Task memory newTask= Task(TuskNum , TitleTask , Description , block.timestamp , false , 0);
         userList[msg.sender].taskList.push(newTask);
         TuskNum++;
     }
    function getAllTasks() external view returns(Task[] memory){
    require(checkUserExists(msg.sender), "Please Create an Account First");
    return userList[msg.sender].taskList;
    } 
    function markTaskCompleted(uint taskNo) external {
    require(checkUserExists(msg.sender), "Please Create an Account First");
    require(taskNo > 0 && taskNo <= userList[msg.sender].taskList.length, "Invalid task number");
    userList[msg.sender].taskList[taskNo - 1].completed = true;
    userList[msg.sender].taskList[taskNo - 1].TaskCompletedAt = block.timestamp;
    }
    function checkUserExists(address pubKey) public view returns (bool) {
        return bytes(userList[pubKey].name).length >0;
    }
    function likedByUser(uint blogID) internal view returns(bool) {
    bytes32 blogKey = keccak256(abi.encodePacked(msg.sender, blogID));
    return likedBlogs[blogKey];
    }

    function addBlogPost(string calldata title, string calldata content) external{
    require(checkUserExists(msg.sender), "Please Create an Account First");
    require(bytes(title).length > 0 ,"Title Cannot Be Empty");
    require(bytes(content).length>0,"Blog Cannot be Empty");
    Blog memory newBlog = Blog(IDCount,title,content , block.timestamp, 0 );
    userList[msg.sender].blogList.push(newBlog);
    IDCount++;
    }

    function getBlogPosts(address userAddress) external view returns (Blog[] memory) {
        require(checkUserExists(msg.sender), "Please Create an Account First");
        require(checkUserExists(userAddress), "User Not Valid");
        return userList[userAddress].blogList;
    }


    function createAccount(string calldata name , string memory nickName) external {
        require( checkUserExists(msg.sender) == false , "User Already Exists!");
        require(bytes(name).length > 0 , "User Name Cannot Be Empty"); 
         require(keccak256(bytes(nickName)) != keccak256(bytes("")), "Email address cannot be empty");
        //add function here that checks whether email already exist in the allUserStruct array
       for (uint i = 0; i < getAllUsers.length; i++) {
        require(
            keccak256(bytes(getAllUsers[i].nickName)) != keccak256(bytes(nickName)),
            "NickName already taken"
        );
    }
        userList[msg.sender].name = name;
        getAllUsers.push(AllUserStruct(name , nickName ,msg.sender));

    }

    function getUsername (address pubKey) external view returns (string memory ){
        require( checkUserExists(pubKey), "User Not Registered!");
        return userList[pubKey].name;
    }

    function checkAlreadyFriends(address pubKey1, address pubKey2 ) internal view returns(bool){
        if(userList[pubKey1].friendList.length > userList[pubKey2].friendList.length){
            address tmp = pubKey1;
            pubKey1 = pubKey2;
            pubKey2 = tmp;
        }

        for(uint256 i = 0; i<userList[pubKey1].friendList.length; i++ ){
            if (userList[pubKey1].friendList[i].pubKey == pubKey2) return true;
        }
        return false;
    } 

    function addFriend(address friend_key, string calldata name) external {
        require(checkUserExists(msg.sender), "Create an Account");
        require(checkUserExists(friend_key), "User Not Registered");
        require(msg.sender != friend_key , "You cannot add yourself!");
        require(checkAlreadyFriends(msg.sender, friend_key)== false,"Already Addes User!");

        _addFriend(msg.sender, friend_key, name);
        _addFriend(friend_key, msg.sender, userList[msg.sender].name);

    }

    function _addFriend(address me , address friend_key , string memory name) internal {
        friend memory newFriend = friend(friend_key, name);
        userList[me].friendList.push(newFriend);
    }

    function getMyFriendList()external view returns(friend[] memory){
        return userList[msg.sender].friendList;
    }

    function _getChatCode(address pubKey1, address pubKey2 ) internal pure returns(bytes32){
        if(pubKey1 < pubKey2){
            return keccak256(abi.encodePacked(pubKey1, pubKey2));
        } else return keccak256(abi.encodePacked(pubKey2, pubKey1));
    }

    function sendMessage(address friend_key, string calldata _msg) external {
        require(checkUserExists(msg.sender), "Please Create an Account First");
        require(checkUserExists(friend_key), "User Not Valid");
        require(checkAlreadyFriends(msg.sender, friend_key), "You're not friends with this User! ");
    
        bytes32 chatCode = _getChatCode(msg.sender, friend_key);
        message memory newMsg = message(msg.sender, block.timestamp, _msg);
        allMessages[chatCode].push(newMsg);
    }

    function readMessage( address friend_key) external view returns(message[] memory){
        bytes32 chatCode = _getChatCode(msg.sender, friend_key);
        return allMessages[chatCode];

    }
    
    function likeBlogPost(address userAddress, uint blogID) external {
    require(checkUserExists(msg.sender), "Please Create an Account First");
    require(checkUserExists(userAddress), "User Not Valid");
    require(blogID < userList[userAddress].blogList.length, "Invalid Blog ID");

    bytes32 blogKey = keccak256(abi.encodePacked(msg.sender, blogID));
    require(!likedBlogs[blogKey], "Blog already liked by user");

    userList[userAddress].blogList[blogID].likes++;
    likedBlogs[blogKey] = true;
    }

    function getAllAppUsers() public view returns ( AllUserStruct[] memory ){
        return getAllUsers;
    }
}
//to-do later
//add donation function
//add a task list for users
//add uri storage for ipfs functionality in Message , Blog 
// add decentralised storage uri save for users
