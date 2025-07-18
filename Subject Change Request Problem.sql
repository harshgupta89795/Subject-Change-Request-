--Subject Change Request Problem

CREATE TABLE SubjectRequest--Created this table for students request to change to new subject
(
	StudentId NVARCHAR(50),
	SubjectId NVARCHAR(50),
	FOREIGN KEY(StudentId) REFERENCES StudentDetails(StudentId),
	FOREIGN KEY(SubjectId) REFERENCES SubjectDetails(SubjectId)
);

CREATE PROCEDURE Students_Request
/*Created a stored procedure with the help of which student can make their new choice by entering the student id and their subject id*/
@StudentId NVARCHAR(50),
@SubjectId NVARCHAR(50)
AS
BEGIN
	INSERT INTO SubjectRequest
	VALUES(@StudentId,@SubjectId)
END

EXEC Students_Request'159103062','PO1493';--Example

CREATE TABLE SubjectAllotments--Created this table as given in the tasks requirements 
(
	StudentId NVARCHAR(50),
	SubjectId NVARCHAR(50),
	Is_valid BIT,--To see the new valid subject currently alloted to the subject
	FOREIGN KEY(StudentId) REFERENCES StudentDetails(StudentId),
	FOREIGN KEY(SubjectId) REFERENCES SubjectDetails(SubjectId)
);

CREATE PROCEDURE Subject_Allotments--Created a aggregate table in which all the subject corresponding to every student id will be dispayed along with the status.
AS
BEGIN
	INSERT INTO SubjectAllotments
	SELECT StudentId,SubjectId,0
	/*Initiallu i am setting the Is_valid to 0, later on i will update it to 1 by checking which subject was alloted previously by refering to the 
	table in the previous week.*/
	FROM StudentPreference;

	UPDATE SubjectAllotments--Here i am updating the Is_valid to 1
	SET Is_valid=1
	FROM SubjectAllotments
    JOIN Allotments
	/*Logic is checking the Allotment table which was created previously in the week and checking which subject was alloted previously correspondding
	to a particular subject id in the StudentAllotments table*/
    ON SubjectAllotments.StudentId=Allotments.StudentId AND SubjectAllotments.SubjectId=Allotments.SubjectId;
END

EXEC Subject_Allotments


/*Here is the main logic in the update_allotment procedure which will update the subject corresponding to every students request based on the availablity
of seats corresponding to a particular subject.*/
CREATE PROCEDURE update_allotments
AS
BEGIN
	DECLARE update_allot CURSOR FOR--Created a curson for row by row assessment in the Subject Request Table
	SELECT DISTINCT StudentId--Here i am extracting the studentid of students who want to chnage the subject
	FROM SubjectRequest

	DECLARE @id NVARCHAR(50)--Declaring a variable to store student id who want change od subject.

	OPEN update_allot--Opening the cursor 
	FETCH Next FROM update_allot--To fetch the next row of data.
	INTO @id;

	WHILE @@FETCH_STATUS=0--Checking the row is not null
	BEGIN
		DECLARE @seats INT;--stores the number of seats left corresponding to the particular subject choosen by the student.
		DECLARE @subject_want NVARCHAR(50);--Subject which the student want
		DECLARE @subject_have NVARCHAR(50);--Cuurently alloted subject of the subject which he/she wants to change.
		DECLARE @status BIT=0;--Stores the status of allotment.

		SELECT @subject_want=SubjectId--Storing the subject id of the subject wanted by the student.
		FROM SubjectRequest
		WHERE @id=StudentId;--Corresponding to that particular student.

		SELECT @subject_have=SubjectId--Storing the subject id of the subject which the student current has
		FROM SubjectAllotments
		Where Is_valid=1 AND StudentId=@id;--filtering on the basis of Is_valid since the subject is currently alooted and not updated.

		SELECT @seats=RemainingSeats--Storing the remaing number of seats left for the subject student want.
		FROM SubjectDetails
		WHERE SubjectId=@subject_want 

		IF @subject_want IS NOT NULL AND @subject_want!=@subject_have--Checking if the subject currently alloted and subject wanted are not sameand subject id is not NULL.
		BEGIN
			IF @seats>0--If there are seats left then
			BEGIN
				UPDATE SubjectAllotments--Updating the Is_valid status to 1 corresponding to the new subject id corresponding to that particular student.
				SET Is_valid=1
				WHERE SubjectId=@subject_want AND StudentId=@id;

				UPDATE SubjectAllotments--Updating the Is_valid status to 0 corresponding to the old subject id corresponding to that particular student.
				SET Is_valid=0
				WHERE SubjectId=@subject_have AND StudentId=@id;

				UPDATE SubjectDetails--Updating the number of seats left now after alloting the new subject to the student.
				SET RemainingSeats=RemainingSeats - 1
				WHERE SubjectId=@subject_want;

				UPDATE SubjectDetails--Updating the number of seats left now after alloting the new subject to the student and releasing the seat for the old subject.
				SET RemainingSeats=RemainingSeats+1
				WHERE SubjectId=@subject_have;

				UPDATE Allotments
				/*This is the original table create in the previous week which stores the subject allotment based on preference and GPA and so here 
				i have updated this also*/
				SET SubjectId=@subject_want
				WHERE StudentId=@id;
			END
		END
		ELSE IF NOT EXISTS(/*This is the boundary condition which i am checking which includes the students in the subject request table which are not
		in the SubjectAllotment table*/
		SELECT 1
		FROM SubjectAllotments
		WHERE StudentId=@id
		) AND @seats>0
		BEGIN/*So for these student i am straight away entering these students in the subjectallotment table and seting their Is_valid to 1 corresponding 
		to that particular student*/
			INSERT INTO SubjectAllotments(StudentId,SubjectId,Is_valid)
			VALUES(@id,@subject_want,1)--Here i am entring the deails in the subjectallotment and setting the Is_valid to 1.

			UPDATE SubjectDetails
			SET RemainingSeats=RemainingSeats-1
			WHERE SubjectId=@subject_want;

			INSERT INTO Allotments(SubjectId,StudentId)--Updating the old table as done above.
			VALUES (@subject_want,@id);

		END
		FETCH NEXT FROM update_allot INTO @id;--Fetching the next subject id from subject request table into id variable.
	END
	CLOSE update_allot;--Closing the cursor.
	DEALLOCATE update_allot;--Deallocating it.
END


EXEC update_allotments--Executing the updated procdeure 

SELECT * FROM Allotments--To check the updated subject id correspinding to students in the old(previous week) table.

SELECT * FROM SubjectAllotments--To check the updated subject id corresponding to every student with their Is_valid Bit.

------------------------------------------------------------THANK YOU---------------------------------------------------------------------------------


