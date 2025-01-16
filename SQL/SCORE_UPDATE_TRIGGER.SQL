-- First, create the function that will handle the level updates
CREATE OR REPLACE FUNCTION public.handle_level_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the current_level based on score thresholds
  NEW.current_level := 
    CASE
      WHEN NEW.score >= 1000 THEN 'Grand Master'
      WHEN NEW.score >= 750 THEN 'Expert'
      WHEN NEW.score >= 500 THEN 'Advanced'
      WHEN NEW.score >= 250 THEN 'Intermediate'
      WHEN NEW.score >= 100 THEN 'Novice'
      ELSE 'Beginner'
    END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger that fires before insert or update on the profile table
CREATE TRIGGER on_level_change
  BEFORE INSERT OR UPDATE OF score
  ON public.profile
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_level_update();