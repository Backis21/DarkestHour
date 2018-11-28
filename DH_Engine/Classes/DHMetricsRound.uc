//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DHMetricsRound extends JSONSerializable;

var DateTime                        StartedAt;
var DateTime                        EndedAt;
var array<DHMetricsRound>           Rounds;
var array<DHMetricsFrag>            Frags;
var array<DHMetricsCapture>         Captures;
var array<DHMetricsConstruction>    Constructions;
var array<DHMetricsRallyPoint>      RallyPoints;
var int                             Winner;

function JSONValue ToJSON()
{
    local JSONObject JSON;

    JSON = (new class'JSONObject')
        .PutString("started_at", StartedAt.IsoFormat())
        .PutInteger("winner", Winner)
        .Put("frags", class'JSONArray'.static.FromSerializables(Frags))
        .Put("captures", class'JSONArray'.static.FromSerializables(Captures))
        .Put("constructions", class'JSONArray'.static.FromSerializables(Constructions))
        .Put("rally_points", class'JSONArray'.static.FromSerializables(RallyPoints));

    if (EndedAt == none)
    {
        JSON.PutNull("ended_at");
    }
    else
    {
        JSON.PutString("ended_at", EndedAt.IsoFormat());
    }

    return JSON;
}

defaultproperties
{
    Winner=-1
}
