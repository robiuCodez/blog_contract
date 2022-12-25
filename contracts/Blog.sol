// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Blog {
    address public owner;
    uint256 public activePostCounter;
    // deleted posts
    uint256 public inactivePostCounter;

    // total posts counter
    uint256 public postCounter;

    // track counts of deleted posts
    uint256 public deletedPostsCounter;

    // deleted posts by author
    mapping(uint256 => address) deletedPostOf;
    // get the author of a post(s)
    mapping(uint256 => address) authorOf;

    // get total posts of author
    mapping(address => uint256) postsOf;

    // check if post exists
    mapping(uint256 => bool) postExists;

    enum Deactivated {
        NO,
        YES
    }

    struct Post {
        uint256 postId;
        string title;
        string content;
        address author;
        Deactivated deleted; // YES / NO
        uint256 createdAt;
        uint256 updatedAt;
    }

    Post[] activePosts;
    Post[] inactivePosts;

    // Post[] posts;

    event Action(
        uint256 id,
        string actionType,
        address indexed executor,
        uint256 timestamp
    );

    // isOwner modifier
    modifier isOwner() {
        require(msg.sender == owner, "Unauthorized Action");
        _;
    }

    constructor() {
        // make the Smart Contract Deployer, the Owner.
        owner = msg.sender;
    }

    function createNewPost(string memory title, string memory content)
        public
        returns (bool)
    {
        // make sure title is not empty
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(content).length > 0, "Content cannot be empty");

        // increase posts counter
        // starts from 1.
        postCounter++;
        authorOf[postCounter] = msg.sender;
        postsOf[msg.sender]++;

        // make blog posts active by default
        activePostCounter++;

        // declare post as "exists"
        postExists[postCounter] = true;

        activePosts.push(
            Post(
                postCounter,
                title,
                content,
                msg.sender,
                Deactivated.NO,
                block.timestamp,
                block.timestamp
            )
        );

        // emit an Event
        emit Action(postCounter, "POST CREATED", msg.sender, block.timestamp);

        return true;
    }

    // check if post exists before trying to modify
    modifier itExists(uint256 _postId) {
        require(postExists[_postId] == true, "Post does not Exist");
        _;
    }

    // verify that action is carried out by post author.
    modifier isAuthor(uint256 _postId) {
        require(
            msg.sender == activePosts[_postId].author,
            "Unauthorized Action"
        );
        _;
    }

    // Update Post
    function updatePost(
        uint256 _postId,
        string memory _title,
        string memory _content
    ) public itExists(_postId) isAuthor(_postId) returns (bool) {
        // make sure title is not empty
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_content).length > 0, "Content cannot be empty");

        // modify post data
        // minus 1 - to get the right post.
        activePosts[_postId - 1].title = _title;
        activePosts[_postId - 1].content = _content;

        // update updated at time.
        activePosts[_postId - 1].updatedAt = block.timestamp;

        // emit Action
        emit Action(_postId, "POST UPDATED", msg.sender, block.timestamp);

        return true;
    }

    function getPostById(uint256 _postId) public view returns (Post memory) {
        return activePosts[_postId - 1];
    }

    function deletePostById(uint256 _postId)
        public
        itExists(_postId)
        isAuthor(_postId) returns (bool)
    {
        // we don't want to delete cause we would like to be able to restore at a later point.
        // delete activePosts[_postId - 1];

        activePosts[_postId - 1].deleted = Deactivated.YES;
        deletedPostsCounter++;

        emit Action(_postId, "POST DELETED", msg.sender, block.timestamp);

        return true;
    }

    // Restore deleted Blog Posts.
    function restoreDeletedPost(uint256 _postId) public returns (bool) {
        activePosts[_postId - 1].deleted = Deactivated.NO;
        deletedPostsCounter--;

        emit Action(_postId, "POST RESTORED", msg.sender, block.timestamp);

        return true;
    }

    // get all posts
    function getAllPosts() public view returns (Post[] memory) {
        return activePosts;
    }

    // get all active posts
    function getActivePosts() public view returns (Post[] memory posts) {
        // create a static sized array with the capacity to
        // accomodate all posts...
        posts = new Post[](postCounter - deletedPostsCounter);

        // loop 2ru all active posts
        for (uint256 i = 0; i < activePosts.length; i++) {
            // add all active posts to "posts"
            // check if post is deactivated or not
            if (posts[i].deleted != Deactivated.YES) {
                posts[i] = activePosts[i];
            }
        }
    }
}
