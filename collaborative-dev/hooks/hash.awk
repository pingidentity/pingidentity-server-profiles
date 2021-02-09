BEGIN
{
    for(n=0;n<256;n++)
    {
        ord[sprintf("%c",n)] = n
    }
}

function hash(text, _prime, _modulo, _ax, _chars, _i)
{
    _prime = 104729;
    _modulo = 1048576;
    _ax = 0;
    split(text, _chars, "");
    for (_i=1; _i <= length(text); _i++)
    {
        _ax = (_ax * _prime + ord[_chars[_i]]) % _modulo;
    }
    return sprintf("%05x", _ax);
}

{
    printf("%s", hash($0));
}