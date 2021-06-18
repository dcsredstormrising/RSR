BlueHQ = GROUP:FindByName( "Northern Blue HQ" )
RedHQ = GROUP:FindByName( "Northern Red HQ" )

BlueCommandCenter = COMMANDCENTER
  :New( BlueHQ, "Blue Command" )
RedCommandCenter = COMMANDCENTER
  :New( RedHQ, "Red Command" )

BlueRecceSetGroup = SET_GROUP:New():FilterCoalitions("blue"):FilterPrefixes( {"Pontiac 1"} ):FilterStart()
RedRecceSetGroup = SET_GROUP:New():FilterCoalitions("red"):FilterPrefixes( {"Pontiac 6"} ):FilterStart()

BLUE_CAS_Set = SET_GROUP:New():FilterPrefixes( {" Blue AF", " Blue Helos"} ):FilterStart()
RED_CAS_Set = SET_GROUP:New():FilterPrefixes( {" Red AF", " Red Helos"} ):FilterStart()

BlueRecceDetection = DETECTION_AREAS:New(BlueRecceSetGroup, 15000)
  :SetAcceptRange(15000)
  :FilterCategories( { Unit.Category.GROUND_UNIT } )

RedRecceDetection = DETECTION_AREAS:New(RedRecceSetGroup, 15000)
  :SetAcceptRange(15000)
  :FilterCategories( { Unit.Category.GROUND_UNIT } )

BlueReconDesignation = DESIGNATE:New( BlueCommandCenter, BlueRecceDetection, BLUE_CAS_Set)
  :SetThreatLevelPrioritization(true)
  :SetMaximumDistanceAirDesignation(15000)
  :SetMaximumDistanceDesignations(15000)
  :SetMaximumDistanceGroundDesignation(15000)
  :SetMaximumDesignations(4)    
  :SetLaserCodes({1682, 1683, 1684, 1685})
  :SetDesignateName("UAV MQ-1")
  :SetLaseDuration(900)
  :AddMenuLaserCode(1113, "Lase with %d for Su-25T")
  :AddMenuLaserCode(1680, "Lase with %d for A-10A")
  :Detect()
--  :__Detect(-1)

RedReconDesignation = DESIGNATE:New( RedCommandCenter, RedRecceDetection, RED_CAS_Set)
  :SetThreatLevelPrioritization(true)
  :SetMaximumDistanceAirDesignation(15000)
  :SetMaximumDistanceDesignations(15000)
  :SetMaximumDistanceGroundDesignation(15000)  
  :SetMaximumDesignations(4)    
  :SetLaserCodes({1686, 1687, 1688, 1689 })
  :SetDesignateName("UAV MQ-1")
  :SetLaseDuration(900)
  :AddMenuLaserCode(1113, "Lase with %d for Su-25T")
  :AddMenuLaserCode(1680, "Lase with %d for A-10A")
  :Detect()
--  :__Detect(-1)
