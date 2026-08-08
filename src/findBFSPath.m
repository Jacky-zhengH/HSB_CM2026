function [found, path] = findBFSPath(adjacency, startNode, goalNode)
%FINDBFSPATH Breadth-first path search for the formal Piece graph.

nodeCount = numel(adjacency);
visited = false(nodeCount, 1);
predecessor = zeros(nodeCount, 1);
queue = zeros(nodeCount, 1);
head = 1;
tail = 1;
queue(tail) = startNode;
visited(startNode) = true;

while head <= tail
    node = queue(head);
    head = head + 1;
    if node == goalNode
        break;
    end
    neighbors = adjacency{node};
    for index = 1:numel(neighbors)
        neighbor = neighbors(index);
        if ~visited(neighbor)
            visited(neighbor) = true;
            predecessor(neighbor) = node;
            tail = tail + 1;
            queue(tail) = neighbor;
        end
    end
end

found = visited(goalNode);
path = zeros(0, 1);
if found
    node = goalNode;
    while node ~= 0
        path = [node; path]; %#ok<AGROW>
        if node == startNode
            break;
        end
        node = predecessor(node);
    end
end
end
