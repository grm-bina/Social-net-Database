/*
use master
drop database SocialNetworkAlbina
*/

create database SocialNetworkAlbina
go

use SocialNetworkAlbina
go

/*
alter table [User]
drop constraint [FK__User__ProfilePic__4222D4EF]
drop table PictureTags
drop table Pictures
drop table Album
drop table PostLikes
drop table Post
drop table MessageReceivers
drop table [Message]
drop table GroupMembers
drop table [Group]
drop table Friendship
drop table [User]
drop table RelationshipStatus
drop table Hometown
*/


create table Hometown
(
	CityID int primary key identity,
	City varchar(50) not null unique
)

create index idx_City
on Hometown(City)


create table RelationshipStatus
(
	StatusID int primary key identity,
	[Status] varchar(50) not null unique 
)

create table [User]
(
	UserID int primary key identity,
	UserFirstName varchar(50) not null,
	UserLastName varchar(50) not null,
	HometownID int foreign key references Hometown(CityID),
	Email varchar(50) not null unique check (Email like '_%@_%._%'),
	BirthDate date,
	Workplace varchar(50),
	TelephoneNumber varchar(15) check ((TelephoneNumber is not null and isnumeric(TelephoneNumber)=1)
									or (TelephoneNumber is null)),
	RelationshipStatusID int foreign key references RelationshipStatus(StatusID),
	InReletionshipWithID int foreign key references [User](UserID)
)

create unique index idx_InReletionshipWithID_notnull
on [User](InReletionshipWithID)
where InReletionshipWithID is not null

create index idx_UserFullName
on [User](UserFirstName,UserLastName)


create table Friendship
(
	UserID int foreign key references [User](UserID),
	FriendWithID int foreign key references [User](UserID),
	IsAccepted bit not null default 0,
	primary key(UserID, FriendWithID)
)

create table [Group]
(
	GroupID int primary key identity,
	GroupName varchar(50) not null unique,
	ManagerID int not null foreign key references [User](UserID)
)

create index idx_GroupName
on [Group](GroupName)

create table GroupMembers
(
	GroupID int not null foreign key references [Group](GroupID),
	UserID int not null foreign key references [User](UserID),
	primary key(GroupID, UserID)
)

create table [Message]
(
	MessageID int primary key identity,
	SenderID int not null foreign key references [User](UserID),
	[Subject] varchar(50) not null default 'No Subject',
	Content varchar(1000) not null,
	MessageDate datetime not null
)

create table MessageReceivers
(
	MessageID int not null foreign key references [Message](MessageID),
	UserID int not null foreign key references [User](UserID),
	IsRead bit not null default 0,
	primary key(MessageID, UserID)
)

create table Post
(
	PostID int primary key identity,
	LoadedByUserID int not null foreign key references [User](UserID),
	PostDate datetime not null,
	TextContent varchar(1000),
	SharedWithGroupID int foreign key references [Group](GroupID),
)

create table PostLikes
(
	PostID int not null foreign key references Post(PostID),
	LikedByUserID int not null foreign key references [User](UserID),
	IsSeenByLoader bit not null default 0,
	primary key(PostID, LikedByUserID)
)

create table Album
(
	PostAlbumID int primary key foreign key references Post(PostID),
	[OwnerID] int not null foreign key references [User](UserID),
	AlbumName varchar(50) not null,
	[Description] varchar(150)
)

create table Pictures
(
	PostPicturesID int primary key foreign key references Post(PostID),
	SourceLink varchar(100) not null check (SourceLink like '_%/_%.jpg'
									or SourceLink like '_%/_%.jpeg'
									or SourceLink like '_%/_%.gif'
									or SourceLink like '_%/_%.png'
									or SourceLink like '_%/_%.webp'
									or SourceLink like '_%/_%.svg'),
	BelongsToAlbumID int not null foreign key references Album(PostAlbumID)
)

alter table [User]
add ProfilePictureID int foreign key references Pictures(PostPicturesID)

create table PictureTags
(
	PictureID int not null foreign key references Pictures(PostPicturesID),
	TaggedUseerID int not null foreign key references [User](UserID),
	IsAccepted bit not null default 0,
	primary key (PictureID, TaggedUseerID)
)