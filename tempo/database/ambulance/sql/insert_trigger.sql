CREATE OR REPLACE FUNCTION course_before_insert_update_trigger()
  RETURNS TRIGGER AS $$
BEGIN
  IF NEW.instructor_id IS NULL THEN
    RAISE EXCEPTION 'Instructor ID cannot be null';
  END IF;

  -- Check if instructor exists and is an instructor
  IF EXISTS (
      SELECT 1
      FROM public.user
      WHERE id = NEW.instructor_id AND is_instructor = TRUE
  ) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'Instructor does not exist or is not an instructor.';
  END IF;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS course_before_insert_update_trigger ON course;

CREATE TRIGGER course_before_insert_update_trigger
  BEFORE INSERT OR UPDATE
  ON course
  FOR EACH ROW
EXECUTE PROCEDURE course_before_insert_update_trigger();