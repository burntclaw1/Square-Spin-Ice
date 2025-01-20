#assume NxN lattice
#gets the ith binary digit (Starting from 0) of the decimal number I
using SparseArrays
using Arpack
using LinearAlgebra
using KrylovKit
using Plots

struct site
    num::Int
    x::Int
    y::Int
end

struct bond
    site1::site
    site2::site
end


function singleOutEvenOddSpins(isEven,range, N)
    #temp2 stores the map and the list
    temp2::Array{Any}=Any[];
    #temp stores the states
    temp::Array{Int}=Int[];
    #stores the states and their corresponding number
    temp1::Dict{Int,Int}=Dict{Int, Int}();
    in::Int=0;
    for i=0:range-1
        count::Int=0;
        n::Int=i;
        while n>0
            count+=1;
            n=n & (n-1);
        end
        if(isEven&&count%2==0)
            in+=1;
            temp1[i]=in;
            push!(temp, i)
        elseif(!isEven&&count%2!=0)
            in+=1;
            temp1[i]=in;
            push!(temp, i)
    end
end
push!(temp2, temp);
push!(temp2, temp1);
    return temp2;

end

function getTi(i, I)
    return mod(I÷(2^(i)), 2);
end

#flips the bits at the digits i and j
#credit: https://stackoverflow.com/questions/18247126/how-to-flip-a-bit-at-a-specific-position-in-an-integer-in-any-language/18247246
function flipBits(i, j, n)
    temp::Int=n⊻(1<<i);
    temp=temp⊻(1<<j);
    return temp;
end




#credit: semibran at https://github.com/semibran/wrap-around/blob/master/index.js
function wrap(n, m)
      return n >= 0 ? n % m : (n % m + m) % m;
end

#which: true: check i for periodic, false: check j for periodic
function addBond(i, j, which, N, bonds, site0)
    newi::Int=which=="i"||which=="ij" ? wrap(i, N) : i;
    newj::Int=which=="j"||which=="ij" ? wrap(j, N) : j;
    tempcount::Int=newj+1+(newi)*N;
    sit::site=site(tempcount, newi,newj);
    bnd::bond=bond(site0, sit);
    push!(bonds, bnd);
end


#assumes list is sorted and contains integers. finds the target a
function binarySearch(a,list, start, fin)
    if(start>=fin)
        return -1;
    end
    mid::Int=start+(fin÷2-start÷2);
    newstart::Int=start;
    newfin::Int=fin;
    curr::Int=list[mid];
    if(curr==a)
        return mid
    else
        if(curr>a)
            newstart=mid;
        else
            newfin=mid;
        end
        return binarySearch(a, list, newstart, newfin);
    end

end

function containsSite(i, bond)
    return bond.site1.num==i||bond.site2.num==i;
end

function recalculateCount(count, i, j, inew, jnew, N)
    #i is row j is col
    tempcount=count;
    if(inew>i)
        tempcount+N;
    elseif(inew<i)
        tempcount-N;
    end
    if(tempcount<1)
        tempcount=N^2+tempcount;
    elseif(tempcount>N^2)
        tempcount=tempcount-N^2;
    end

    if(jnew>j)
        if(j%N==0)
            tempcount-=(N-1);
        else
            tempcount+=1;
        end
    elseif(jnew<j)
        if(j%N==1)
            tempcount+=(N-1);
        else
            tempcount-=1;
        end
    end
return tempcount;

end

function upperRight(i, j, N, bonds, site0)
    if(j!=N-1)
        addBond(i-1, j+1, "ij", N, bonds, site0);
    end
end

function bottomRight(i, j, N, bonds, site0)
    if(j!=N-1)
        addBond(i+1, j+1, "ij", N, bonds, site0);
    end
end

function bottomLeft(i, j, N, bonds, site0)
    if(j==0)
        addBond(i+1, j-1, "ij", N, bonds, site0);
    end
end

function upperLeft(i, j, N, bonds, site0)
    if(j==0)
        addBond(i-1, j-1, "ij", N, bonds, site0);
    end
end

function bondList(N)
    println("timing bondlist");
    @time begin
    bonds::Array{bond}=bond[];
    if(N<=1)
        return bonds;
    end
    count::Int=0;
    for i=0:N-1
        for j=0:N-1
            count+=1;
            #bug: ened to recaluate count given current count and relative position
            site0::site=site(count, i, j);

            if(i!=N-1)
                addBond(i+1, j, "i", N, bonds, site0);
            end
            if(i==0)
                addBond(i-1, j, "i", N, bonds, site0);
            end

            if(j!=N-1)
                addBond(i, j+1, "j", N, bonds, site0);
            end

            if(j==0)
                addBond(i, j-1, "j", N, bonds, site0);
            end

            if(i%2==0)
                #odd no \ and even no /
                if(count%2==0)
                    upperRight(i, j, N, bonds, site0);
                    bottomLeft(i, j, N, bonds, site0);
                else
                    upperLeft(i, j, N, bonds, site0);
                    bottomRight(i, j, N, bonds, site0);
                end
            else
                if(count%2!=0)
                    upperRight(i, j, N, bonds, site0);
                    bottomLeft(i, j, N, bonds, site0);
                else
                    upperLeft(i, j, N, bonds, site0);
                    bottomRight(i, j, N, bonds, site0);
                end
            end

        end
    end
    println(length(bonds));
end
    return bonds;
end


#implementation of kernighan's algorithm (counting number of 1s)
function singleOutNUpSpins(N, range)
    #temp2 stores the map and the list
    temp2::Array{Any}=Any[];
    #temp stores the states
    temp::Array{Int}=Int[];
    #stores the states and their corresponding number
    temp1::Dict{Int,Int}=Dict{Int, Int}();
    in::Int=0;
    for i=0:range-1
        count::Int=0;
        n::Int=i;
        while n>0
            count+=1;
            if count>N
                break;
            end
            n=n & (n-1);
        end
        if(count==N)
            in+=1;
            temp1[i]=in;
            push!(temp, i)

    end
end
println("THE STATES",length(temp));
push!(temp2, temp);
push!(temp2, temp1);
    return temp2;

end


function constructHamiltonian(states, bonds, N, J, h)
    #loop through ALL the possible states...
    list=states[1];
    map=states[2];
    #println(states);
    H::SparseMatrixCSC{Float64}=spzeros(Int, length(list),length(list));
    for i=1:length(list)
        #NOW loop through all the possible SITES
        for j=1:N*N
            #for this particular site, find ALL of its bonds
            for z=1:length(bonds)
                #get the number of the thing it is bonding with!
                if containsSite(j,bonds[z])
                    bond1::Int=bonds[z].site1.num;
                    bond2::Int=bonds[z].site2.num;
                    if(bond1!=j)
                        temp::Int=bond1;
                        bond1=bond2;
                        bond2=temp;
                    end
                    theThing= getTi(bond1-1,list[i]) == 1 ? (1/2)*h/4 : -(1/2)*h/4;
                    H[i,i]+= theThing;
                        #flip the bits at those relevant places
                        b::Int=flipBits(bond1-1, bond2-1,list[i]);
                        t::Int=map[b];
                        H[i,t]=(1/2)*J/2;
                        end
                    end

                end
            end
        return H;
end

function calculateEigensystem(N, J, h)
    @time begin
    eigenvalues::Array{Any}=Any[];
    bonds::Array{bond}=bondList(N);
    evenSpins::Array{Any}=singleOutEvenOddSpins(true, 2^(N*N), N);
        oddSpins::Array{Any}=singleOutEvenOddSpins(false, 2^(N*N), N);
        println("STARTING EVEN");
        HtempEven::SparseMatrixCSC{Float64}=constructHamiltonian(evenSpins, bonds, N, J,h);

        println("STARTING ODD");
        HtempOdd::SparseMatrixCSC{Float64}=constructHamiltonian(oddSpins, bonds, N, J, h);
        println(HtempEven);
        println(HtempOdd);

        eigtemp=eigs(HtempEven);
        eigtemp2=eigs(HtempOdd);
        append!(eigenvalues, eigtemp[1]);
        append!(eigenvalues, eigtemp2[1]);
    end
    return eigenvalues;

end

function binarySearchIt(a, list)
    #println("starting time for binary search");
    i=1;
    j=length(list);
    mid=i+(j÷2-i÷2);
    while(j>i)
        if(list[mid]==a)
            return mid;
        else
            if(a>list[mid])
                i=mid+1;
                mid=i+(j÷2-i÷2);
            else
                j=mid-1;
                mid=i+(j÷2-i÷2);
        end

    end
end
    return -1;
end

function runL()
    println("starting");
    #bonds=bondList(4);
    #println(bonds);
    #println(length(bonds));
    J=-1;
    h=0;

    eigenvalues=calculateEigensystem(4, J, h);
    println(eigenvalues);
end

runL();
