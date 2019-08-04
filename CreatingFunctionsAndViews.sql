/*
use master
go
*/

use SocialNetworkAlbina
go

/*
drop view PictureTagsLeftJoinPostLikes
drop function getPicturesUserTaggedOn
drop function getGroupsIDbyUserID
drop view PostAllData
drop function getFriendsIDbyUserID
go
*/

-- function to show friends-id of 1 selected(connected) user
create function getFriendsIDbyUserID
(@CurrentUserID int)
returns table
as return
(
select FriendWithID
from Friendship
where IsAccepted=1 and UserID=@CurrentUserID
)
go

-- view with all post-data (include user-full name, connected albums and pictures)
create view PostAllData
as
select pst.PostID, pst.LoadedByUserID, u.UserFirstName+' '+u.UserLastName as UserFullName, pst.PostDate, pst.SharedWithGroupID, g.GroupName, pst.TextContent,
	   a.PostAlbumID, a.AlbumName, a.[Description], a.OwnerID,
	   p.PostPicturesID, p.BelongsToAlbumID, p.SourceLink
from Post pst left join Album a on pst.PostID=a.PostAlbumID
			  left join Pictures p on pst.PostID=p.PostPicturesID
			  left join [User] u on pst.LoadedByUserID=u.UserID
			  left join [Group] g on pst.SharedWithGroupID=g.GroupID 
go

-- function to show groups-id of specific user
create function getGroupsIDbyUserID
(@CurrentUserID int)
returns table
as return
(
select GroupID
from GroupMembers
where UserID=@CurrentUserID
)
go

-- view with all message-data (message-table + message-receivers)
create view MessageAllData
as
select m.MessageID, m.MessageDate, m.[Subject], m.Content, m.SenderID, us.UserFirstName+' '+us.UserLastName as SenderFullName,
	   mr.UserID as ReceiverID, ur.UserFirstName+' '+ur.UserLastName as ReceiverFullName, mr.IsRead
from [Message] m join MessageReceivers mr on m.MessageID=mr.MessageID
				 join [User] us on m.SenderID=us.UserID
				 join [User] ur on mr.UserID=ur.UserID
go

-- function to show all pictures where specific user tagged (alone and with other users tagged too)
create function getPicturesUserTaggedOn
(@CurrentUserID int)
returns table
as return
(
select PictureID
from PictureTags
where TaggedUseerID=@CurrentUserID
	  and IsAccepted=1
)
go

-- view to show pictures with tagged users and likes only users that tagged on
--(if user tagged but dont liked the picture - the tag is displaying and the like is null)
create view PictureTagsLeftJoinPostLikes
as
select *
from PictureTags t left join PostLikes l on t.PictureID=l.PostID
										 and t.TaggedUseerID=l.LikedByUserID
where t.IsAccepted=1
go