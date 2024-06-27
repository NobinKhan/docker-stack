CREATE OR REPLACE FUNCTION enroll_before_insert_update_trigger()
  RETURNS TRIGGER AS $$
BEGIN
  IF NEW.student_id IS NULL THEN
    RAISE EXCEPTION 'Student ID cannot be null';
  END IF;

  -- Check if Student exists and is an Student
  IF EXISTS (
      SELECT 1
      FROM public.user
      WHERE id = NEW.student_id AND is_student = TRUE
  ) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'student does not exist or is not an student.';
  END IF;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS enroll_before_insert_update_trigger ON enrollment;

CREATE TRIGGER enroll_before_insert_update_trigger
  BEFORE INSERT OR UPDATE
  ON enrollment
  FOR EACH ROW
EXECUTE PROCEDURE enroll_before_insert_update_trigger();