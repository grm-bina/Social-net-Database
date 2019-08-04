/*
use master
go
*/

use SocialNetworkAlbina
go

-- 1. Show User’s News Feed
-- Display the list of posts that should be seen on the news feed page (All my Friend posts).
-- Choose the connected user and Order the posts by posted date. (Specific user)
select *
from PostAllData
where LoadedByUserID in (select * from getFriendsIDbyUserID(3))
order by PostDate desc
go

-- 2. Show Users in my groups
-- Display users who belong to at least three groups that I belong to. (Specific user)
with UsersWithCommonGropusWithSelectedUser as
	(
	select GroupID, UserID
	from GroupMembers
	where GroupID in (select * from getGroupsIDbyUserID(6)) -- (6 is the current user)
	),
	UsersWithThreeOrMoreCommonGroups as
	(
	select UserID, count(GroupID) as NumberOfCommonGroups
	from UsersWithCommonGropusWithSelectedUser
	group by UserID
	having count(GroupID)>=3 and UserID <> 6 -- (6 is the current user)
	)
select uc.UserID, u.UserFirstName + ' ' + u.UserLastName as UserFullName, uc.NumberOfCommonGroups
from UsersWithThreeOrMoreCommonGroups uc join [User] u on uc.UserID=u.UserID
go

-- 3. What are the Highlight posts?
-- Display posts order by number of likes (order them from the most liked), don’t show posts that has no likes at all.
with PostsNumOfLikes as
	(
	select PostID, count(LikedByUserID) as NumberOfLikes
	from PostLikes
	group by PostID
	)
select pd.PostID, pl.NumberOfLikes, pd.[LoadedByUserID], pd.[UserFullName], pd.[PostDate], pd.[SharedWithGroupID], pd.[GroupName],
	   pd.[TextContent], pd.[PostAlbumID], pd.[AlbumName], pd.[Description], pd.[PostPicturesID], pd.[BelongsToAlbumID], pd.[SourceLink]
from PostAllData pd join PostsNumOfLikes pl on pd.PostID=pl.PostID
order by pl.NumberOfLikes desc
go

-- 4. Users I may know
-- Suggest me users which are not my friends but we have many friends in common. Order them by amount of mutual friends. (Specific user)
with UsersAreNotFriendsWithSelectedUser as
	(
	select UserID
	from [User]
	where UserID not in (select * from getFriendsIDbyUserID(1)) and  UserID <> 1 -- (1 is the current user)
	),
	UsersWithCommonFriends as
	(
	select f.UserID, f.FriendWithID
	from Friendship f join UsersAreNotFriendsWithSelectedUser unf on f.UserID=unf.UserID
	where f.FriendWithID in (select * from getFriendsIDbyUserID(1)) -- (1 is the current user)
	),
	NumOfCommonFriendsByUser as
	(
	select UserID, count(FriendWithID) as NumberOfCommonFriends
	from UsersWithCommonFriends
	group by UserID
	)
select n.UserID, u.UserFirstName + ' ' + u.UserLastName as UserFullName, n.NumberOfCommonFriends
from [User] u join NumOfCommonFriendsByUser n on u.UserID=n.UserID
order by  n.NumberOfCommonFriends desc
go

-- 5. Best Friend
-- For each user display the best friend. Best Friend is the one who sent me the maximum messages and he likes at least 5 of my Posts.
with NumOfSendedMessages as
	 (
	 select SenderID, ReceiverID, count(MessageID) as NumberOfSendedMessages
	 from MessageAllData
	 group by SenderID, ReceiverID
	 ),
	 NumbOfLikedPosts as
	 (
	 select p.LoadedByUserID, pl.LikedByUserID, count(p.PostID) as NumberOfLikedPosts
	 from Post p join PostLikes pl on p.PostID=pl.PostID
	 group by p.LoadedByUserID, pl.LikedByUserID
	 ),
	 NumOfMessagesAndNumOfLikesFiltredByLikesNumAndFriendship as
	 (
	 select f.UserID, f.FriendWithID as FriendID,
			m.NumberOfSendedMessages as NumberOfSendedByFriendMessages,
			p.NumberOfLikedPosts as NumberOfLikedByFriendPosts
	 from NumOfSendedMessages m join NumbOfLikedPosts p on m.SenderID=p.LikedByUserID
													   and m.ReceiverID=p.LoadedByUserID
								join Friendship f on  m.SenderID=f.FriendWithID
												  and p.LikedByUserID=f.FriendWithID
												  and m.ReceiverID = f.UserID
												  and p.LoadedByUserID=f.UserID
	 where p.NumberOfLikedPosts>=5
	 ),
	 MaximumNumOfMessageByUser as
	 (
	 select UserID, max(NumberOfSendedByFriendMessages) as MaxNumMessage
	 from NumOfMessagesAndNumOfLikesFiltredByLikesNumAndFriendship
	 group by UserID
	 ),
	 FiltredByMaxMessages as
	 (
	 select n.UserID, n.FriendID, n.NumberOfLikedByFriendPosts, n.NumberOfSendedByFriendMessages 
	 from NumOfMessagesAndNumOfLikesFiltredByLikesNumAndFriendship n join MaximumNumOfMessageByUser m on n.UserID=m.UserID
																	 and n.NumberOfSendedByFriendMessages=m.MaxNumMessage
	 )
	 select fm.UserID, u.UserFirstName+' '+u.UserLastName as UserFullName, fm.FriendID as BestFriendID,
			uf.UserFirstName+' '+uf.UserLastName as BestFriendFullName
	 from FiltredByMaxMessages fm join [User] u on fm.UserID=u.UserID
								  join [User] uf on fm.FriendID=uf.UserID
go

-- 6. Portrait
-- Display list of pictures which I am the only person who tagged on. 
select PictureID
from getPicturesUserTaggedOn(7) -- 7 is the current user
where PictureID not in (
						select PictureID
						from PictureTags
						where PictureID in (select * from getPicturesUserTaggedOn(7)) -- 7 is the current user
							  and IsAccepted=1
							  and TaggedUseerID <> 7 -- 7 is the current user
						)
go

-- 7. Administrator Statistics
-- Display the Usage of the website components per year. How many posts were written, how many pictures and Albums were uploaded.
-- Order the Result by year. 
select YEAR(PostDate) as [Year], count(PostID) as TotalNumberOfPosts, count(PostAlbumID) as NumberOfAlbums,
	   count(PostPicturesID) as NumberOfPictures, count(PostID)-count(PostAlbumID)-count(PostPicturesID) as NumberOfTextPosts
from PostAllData
group by YEAR(PostDate)
go

-- 8. We like our picture
-- Display pictures which all the users tagged on it, like it.
-- For example, Tom, Danni and Avi were tagged on a picture which the three of them liked will be returned from the query.
with PicturesIDLikedAllUsersTagedOn as
	(
	select distinct PictureID
	from PictureTagsLeftJoinPostLikes
	where PictureID not in (
							select PictureID
							from PictureTagsLeftJoinPostLikes
							where LikedByUserID is null
							)
	)
select [PostPicturesID] as PictureID, [SourceLink]
from Pictures p join PicturesIDLikedAllUsersTagedOn l on p.PostPicturesID=l.PictureID
go