{{/*
  Call index function recursively. Check on each recursive call that the key exists. Instead of throwing an error if the key doesn't exist, return empty String.
  The return type is always String. If another return type is required, use this function to test if the value exists and then access that value with the index function.
*/}}
{{- define "eric-lcm-git-repository.indexRecursive" -}}
    {{- $keys := (rest .) -}}
    {{- $dict := first . -}}
    {{- $innerValue := index $dict (first $keys) -}}
    {{ if not (kindIs "invalid" $innerValue) }}
        {{- $keysLeft := rest $keys -}}
        {{- if $keysLeft -}}
            {{- $args := prepend $keysLeft $innerValue -}}
            {{- include "eric-lcm-git-repository.indexRecursive" $args -}}
        {{- else -}}
            {{- $innerValue -}}
        {{- end -}}
    {{- end -}}
{{- end -}}


{{/*
  Similar to "indexRecursive", except it returns "_invalid_" instead of empty String if they key doesn't exist.
  This allows us to differentiate between non-existing fields and fields with an empty value.
*/}}
{{- define "eric-lcm-git-repository.indexRecursiveWithEmpty" -}}
    {{- $keys := (rest .) -}}
    {{- $dict := first . -}}
    {{- $innerValue := index $dict (first $keys) -}}
    {{ if not (kindIs "invalid" $innerValue) }}
        {{- $keysLeft := rest $keys -}}
        {{- if $keysLeft -}}
            {{- $args := prepend $keysLeft $innerValue -}}
            {{- include "eric-lcm-git-repository.indexRecursiveWithEmpty" $args -}}
        {{- else -}}
            {{- $innerValue -}}
        {{- end -}}
    {{ else }}
        {{- "_invalid_" -}}
    {{- end -}}
{{- end -}}


{{/*
Given a list of .Values and any number of optional parameter names (including path), returns the first parameter that has a value.
Uses the indexRecursive function, so it is safe to use even if a parameter is not defined.
*/}}
{{- define "eric-lcm-git-repository.firstOptional" -}}
    {{- $values := first . -}}
     {{- $parameters := rest . -}}
     {{- if $parameters -}}
         {{- $currentParameter := first $parameters -}}
         {{- $indexRecursiveArgs := prepend (splitList "." $currentParameter) $values -}}
         {{- $currentValue := include "eric-lcm-git-repository.indexRecursive" $indexRecursiveArgs -}}
         {{- if $currentValue -}}
             {{- $currentValue -}}
         {{- else -}}
             {{- $remainingParameters := rest $parameters -}}
             {{- $recursiveArgs := prepend $remainingParameters $values -}}
             {{- include "eric-lcm-git-repository.firstOptional" $recursiveArgs -}}
         {{- end -}}
     {{- end -}}
{{- end -}}


{{/*
Similar to "firstOptional", except it returns an empty value if a field exists and has an empty value.
If none of the given fields exist, the value "_invalid_" will be returned.
*/}}
{{- define "eric-lcm-git-repository.firstOptionalWithEmpty" -}}
    {{- $values := first . -}}
     {{- $parameters := rest . -}}
     {{- if $parameters -}}
         {{- $currentParameter := first $parameters -}}
         {{- $indexRecursiveArgs := prepend (splitList "." $currentParameter) $values -}}
         {{- $currentValue := include "eric-lcm-git-repository.indexRecursiveWithEmpty" $indexRecursiveArgs -}}
         {{- if not ($currentValue | eq "_invalid_") -}}
             {{- $currentValue -}}
         {{- else -}}
             {{- $remainingParameters := rest $parameters -}}
             {{- $recursiveArgs := prepend $remainingParameters $values -}}
             {{- include "eric-lcm-git-repository.firstOptionalWithEmpty" $recursiveArgs -}}
         {{- end -}}
     {{- else -}}
         {{- "_invalid_" -}}
     {{- end -}}
{{- end -}}